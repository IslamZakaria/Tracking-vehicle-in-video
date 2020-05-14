function runTestCase3( VideoName )

clc; 
close all; 
warning off;
%Step 1 - Import Video and Initialize Foreground Detector
foregroundDetector = vision.ForegroundDetector('NumGaussians', 5, ...
            'NumTrainingFrames', 50,'MinimumBackgroundRatio',0.63);
videoReader = vision.VideoFileReader(VideoName);
for i = 1:150
    frame = step(videoReader); % read the next video frame
    foreground = step(foregroundDetector, frame);
end
filteredForeground = imopen(foreground, strel('square', 3));
filteredForeground = imclose(filteredForeground, strel('square', 15));
filteredForeground = imfill(filteredForeground, 'holes');

%Step 2 - Detect Cars in an Initial Video Frame
 %bounding cars
blobAnalysis1 = vision.BlobAnalysis('BoundingBoxOutputPort', true,...
    'AreaOutputPort', false, 'CentroidOutputPort', false,...
    'MinimumBlobArea', 0);

blobAnalysis2 = vision.BlobAnalysis('OrientationOutputPort', true);

bbox = step(blobAnalysis1, filteredForeground);
deg = step(blobAnalysis2, filteredForeground);

%Step 3 - Process the Rest of Video Frames
videoPlayer = vision.VideoPlayer('Name', 'Detected Vehicles');
videoReader = vision.VideoFileReader(VideoName);
v = VideoReader(VideoName);
videoWidth=v.Width;
videoHeight=v.Height;
videoPlayer.Position(3:4) = [600,500];

totalDistance=double(0);
Degree=double(1);
ODeg=double(1);
NDeg=double(1);
totalTime=double(0);
oldX=double(0); currentX=double(0);
oldY=double(0); currentY=double(0);
savePosSingle=[];
savePosDouble=[];
paths=[];

while ~isDone(videoReader)
    totalTime = totalTime + 1;
    frame = step(videoReader); % read the next video frame
    % Detect the foreground in the current video frame
    foreground = step(foregroundDetector, frame);
    % Use morphological opening to remove noise in the foreground    
    filteredForeground = imopen(foreground, strel('square', 3));
    filteredForeground = imclose(filteredForeground, strel('square', 15));
    filteredForeground = imfill(filteredForeground, 'holes');
    % Detect the connected components with the specified minimum area, and
    % compute their bounding boxes
    bbox = step(blobAnalysis1, filteredForeground);%bbox X1,Y1 --> width,hight (X2: x1+width , Y2: y1+hight)
    deg = step(blobAnalysis2, filteredForeground);
    % Draw bounding boxes around the detected cars and add it's
    % speed,degree and get there path
    [boxI,boxJ]=size(bbox);
    if boxI>=1%here i'm going to do some threshold. first for Width&Height of objects on bounding box then on there sizes 
        for i = 1:boxI
            if ( bbox(i,3)>(9*videoWidth)/10 ) || ( bbox(i,3)<(1*videoWidth/10) ) || ( bbox(i,4)>(9*videoHeight)/10 ) || ( bbox(i,4)<(1*videoHeight)/10 ) 
                bbox(i,:)=[0,0,0,0];
            else
                sizeBBox=bbox(i,3)*bbox(i,4);
                if sizeBBox<=1900 || sizeBBox>=170000
                    bbox(i,:)=[0,0,0,0];
                    savePosSingle=[];
                end
                if totalTime>1 && oldX>0 && oldY>0 && mod(totalTime,5)==0
                    currentX=bbox(i,1);
                    currentY=bbox(i,2);
                    NDeg=deg(i);
                    savePosSingle=[savePosSingle,currentX+bbox(i,3),currentY+(bbox(i,4)/2)];
                    totalDistance = totalDistance + ( (currentX-oldX)*(currentX-oldX) + (currentY-oldY)*(currentY-oldY) )^1/2;
                    Degree=abs(NDeg-ODeg);
                    oldX=bbox(i,1);
                    oldY=bbox(i,2);
                    ODeg=deg(i);
                else
                    oldX=bbox(i,1);
                    oldY=bbox(i,2);
                    if oldX>0 && oldY>0
                        savePosSingle=[savePosSingle,oldX+bbox(i,3),oldY+(bbox(i,4)/2)];
                    end
                    ODeg=deg(i);
                end
            end
        end
    else %video has no objects
        totalDistance=0;
        Degree=1;
        totalTime=0;
        savePosSingle=[];
        savePosDouble=[];
        paths=[];
    end 
    speed = totalDistance / (totalTime);
    speed = mod(speed,100);
    Degree = mod(Degree,100);
    [sizeSingleH,sizeSingleW] = size(savePosSingle);
    if isempty(savePosSingle)
        paths=[];
    elseif mod(sizeSingleW,2)==0 && mod(sizeSingleW,4)>0
        savePosSingle=[savePosSingle,savePosSingle(sizeSingleH,sizeSingleW-1),savePosSingle(sizeSingleH,sizeSingleW)];
        [heightPaths,widthPaths]=size(paths);
        [sizeSingleH,sizeSingleW] = size(savePosSingle);
        if sizeSingleW==4 && sizeSingleH==1
            paths=savePosSingle;
        else
            savePosDouble=reshape(savePosSingle,[],2);
            paths=transpose(savePosDouble);  
        end       
    end
    label_text = ['Velocity: ' num2str(speed,'%0.2f') ' PpF , ', 'Degree: ' num2str(Degree)];
    result = insertObjectAnnotation(frame,'rectangle',bbox,label_text,'TextBoxOpacity',0.9,'FontSize',20,'LineWidth',3,'Color','cyan');
    result = insertShape(result, 'Line', paths, 'LineWidth', 3);
    step(videoPlayer, result);  % display the results
    %step(videoPlayer, filteredForeground);
end
release(videoReader); % close the video file
clear all;

end

