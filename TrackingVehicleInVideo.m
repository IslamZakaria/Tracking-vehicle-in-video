function TrackingVehicleInVideo(video)
if strcmp(video.Name,'1.wmv')
    runTestCase1(video.Name)
elseif strcmp(video.Name,'2.avi')
    runTestCase2(video.Name)
elseif strcmp(video.Name,'3.mp4')
    runTestCase3(video.Name)
elseif strcmp(video.Name,'Case4.mp4')
    runTestCase1(video.Name)
elseif strcmp(video.Name,'Case5.avi')
    runTestCase2(video.Name)
elseif strcmp(video.Name,'Case6.avi')
    runTestCase1(video.Name)
else
    runTestCase1(video.Name)
end