close all;
clear all;
tic
%im = imread('C:\Users\Admin\Desktop\New_exp_photos\illuminance\11.jpg');
im = imread('D:\University\4 course\Диплом\РГБ1\макс\РГБ\Number Plate Detection\New_exp_photos\illuminance\11.jpg');

im3 = im;% збереження змінної із вхідним зображенням% save variable with input image
imgray = rgb2gray(im); % переведення зображення в сірі напівтони% conversion of the image to gray halftones
%imshow(imgray); hold on;
imgray = imcrop(imgray, [400 300 500 500]);
%imgray = imcrop(imgray, [450 490 400 300]); % обрізка пікселів зображення% crop image pixels
%imshow(imgray); hold on;
G = fspecial('gaussian',[4 4],2); %Розмиття зображення фільтром Гауса% Blur image with Gaussian filter
 %# Filter it
imgray = imfilter(imgray,G,'same');
%imshow(imgray); hold on;
corners = detectFASTFeatures(imgray); %визначення характерних точок детектором FAST% determination of characteristic points by the FAST detector
imshow(imgray); hold on;
plot(corners.selectStrongest(200)); % Відображення точок з вибраною масою% Display points with selected mass
pause(2);


for i=1:length(corners.Location) % Запис координат х,у кожної характерної точки% Record the coordinates of x, at each characteristic point
    x(i)= corners.Location(i);
    y(i)= corners.Location(i,2);
end
for i=1:length(corners.Location) % Розрахування маси кожної характерної точки за відстання між ними% Calculation of the mass of each characteristic point for the distance between them
    mass(i)=0;
    for j=1:length(corners.Location)
    dist(i,j)=sqrt((x(i)-x(j))^2+(y(i)-y(j))^2); % рівняння визначення відстані% equation for determining the distance
    if  dist(i,j)<=60 %порівняння відстані між точками з визначеним порогом% comparison of the distance between points with a certain threshold
        mass(i)= mass(i)+1;
    end
    end
end
masso=6;   % Запис початкового порогу маси точок% Record the initial threshold of the mass of points
num_of_iter=1; % ініціалізація змінної підрахунку ітерацій циклу% initialization of the cycle iteration count variable

while(1) % Початок циклу визначення номерної таблички та символів на ній% Start of the number plate definition cycle and the symbols on it
   
for i=1:length(corners.Location) % Цикл відсіювання характерних точок із занадто малою масою% Cycle of elimination of characteristic points with too little mass
    if mass(i)<=masso
        mass(i)=0;
    else
        x_1(i)=x(i); % координати точок, які пройшли перевірку% coordinates of points that have been checked
        y_1(i)=y(i);
    end
end
x_1=nonzeros(x_1)'; % відсіювання точок з 0 координатами% screening points with 0 coordinates
y_1=nonzeros(y_1)';
imshow(imgray); hold on;
plot(x_1,y_1,'c*'); % Відображення характерних точок які пройшли всі перевірки% Display of characteristic points that have passed all checks

Mleft = double(min(x_1)-10);%left crop edge point
Mright = double(max(x_1)+20);%right crop edge point
Mupper = double(min(y_1)-10);%upper crop edge point
Mlower =  double(max(y_1)+10);%lower crop edge point

X=400+Mleft*(num_of_iter); %розрахунок краю обрізки після кожної ітерації% calculation of the trimming edge after each iteration
Y=300+Mupper*(num_of_iter);

num_of_iter=num_of_iter+1; % лічильник ітерацій циклу% cycle iteration counter

imgray = imcrop(imgray, [Mleft Mupper Mright-Mleft Mlower-Mupper]); % Обрізка зображення по крайніх характерних точках% Crop image at extreme characteristic points
figure, imshow(imgray);
imbin = imbinarize(imgray); % бінаризація зображення% image binarization

im = edge(imgray, 'canny'); % Виділення контурів на обрізаному зображенні методом Превітта% Select contours on the cropped image using the Previtt method
figure, imshow(im);
figure, imshow(imbin);% бінаризоване обрізане зображення% binary cropped image
%Below steps are to find location of number plate
Iprops=regionprops(imbin,'BoundingBox','Area', 'Image'); % знаходження властивостей зображення: координати та розміри найменшого прямокутника, фактична кількість пікселів в регіоні, бінарне зображення того ж розміру що і BoundingBox повернене в якості бінарного масиву% finding image properties: coordinates and dimensions of the smallest rectangle, actual number of pixels in the region, binary image of the same size as BoundingBox returned as a binary array
area = Iprops.Area; %фактична кількість пікселів в регіоні% actual number of pixels in the region
count = numel(Iprops); % кількість елементів масиву % number of elements of the array
maxa= area; 
boundingBox = Iprops.BoundingBox;

for i=1:count               % Визначення рамки % Frame definition
   if maxa<Iprops(i).Area
       maxa=Iprops(i).Area;
       boundingBox=Iprops(i).BoundingBox;
   end
end    

im = imcrop(imbin, boundingBox);%crop the number plate area
figure, imshow(im);
%im = bwareaopen(~im, 50);
im = bwareaopen(~im, 1); %remove some object if it width is too long or too small than 50
figure, imshow(im);
 [h, w] = size(im);%get width and height

imshow(im);

Iprops=regionprops(im,'BoundingBox','Area', 'Image'); %reading the letter
count = numel(Iprops);
noPlate=[]; % Initializing the variable of number plate string.

for i=1:count
   ow = length(Iprops(i).Image(1,:)); %висота зображення% image height
   oh = length(Iprops(i).Image(:,1)); % ширина зображення% image width
   if ow<(h/2) && oh>(h/3)
       letter=Letter_detection(Iprops(i).Image); % Reading the letter corresponding the binary image.
       noPlate=[noPlate letter] % Appending every subsequent character in noPlate variable.
   end
end
masso=masso+1; % збільшення порогу маси точок з кожним циклом  % increase in the threshold mass of the points with each cycle 
if masso > 13 % Обмеження величини маси точок% Limit the value of the mass of points
    masso_err = 0;
    break
end

if length(noPlate)==9 % Виправлення хибного визначення першого символу% Corrects the incorrect definition of the first character
    if isnumeric(noPlate(3))==0
   
    noPlate(1)='';
end
end
if length(noPlate)==8 %вивід символів зчатаних з таблички% output of characters read from the plate
    masso_err = 1;
    noPlate
    break
end
close all
end
toc
% Виділення рамкою області номера та відображення зчитаних символів на
% початковому зображенні% Frame the area of the number and display the read characters on
% to the original image
if masso_err == 1
imshow(im3); hold on;
%c=2.33;
%rectangle('Position',[(X+boundingBox(1))*c+1000 (Y+boundingBox(2))*c+360 boundingBox(3) boundingBox(4)],'EdgeColor','r','LineWidth',3);
%text((X+boundingBox(1))*c+660,(Y+boundingBox(2)+2*boundingBox(4))*c+360,noPlate,'Color','red','FontSize',16);
rectangle('Position',[X+boundingBox(1) Y+boundingBox(2) boundingBox(3) boundingBox(4)],'EdgeColor','r','LineWidth',3);
text(X+boundingBox(1),Y+boundingBox(2)+2*boundingBox(4),noPlate,'Color','red','FontSize',16);

 end