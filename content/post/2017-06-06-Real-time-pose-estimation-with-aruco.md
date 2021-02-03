+++
author = "nimodai"
title = "Real-time-pose-estimation-with-aruco"
date = "2017-06-06"
description = ""
tags = [
    "OpenCV",
]
+++

> Project in  [github](https://github.com/nimohunter/Real_Time_pose_estimation_with_aruco)


This projects base on [Real Time pose estimation of a textured object](http://docs.opencv.org/3.1.0/dc/d2c/tutorial_real_time_pose.html) and here is [Code](https://github.com/opencv/opencv/tree/master/samples/cpp/tutorial_code/calib3d/real_time_pose_estimation)

if you cannot run this offical code, maybe you can use this, [My base Real time estimate prject](https://github.com/nimohunter/Opencv_Aruco/tree/master/Project_Real_Time_pose_estimation_of_a_textured_object), which just modify a little to make the offical code can build and run successful. (maybe the offical code is old and cannot run...)

Request:
1. Opencv3 with opencv_contrib(this extra-package include aruco)
2. Qt Creator

---
As the name - "Real time pose estimation with aruco", I use the Opecv3 method `SovlvePnp` to Solve this problem, you can see the final result at [TODO](https://youtube_address)

"With Aruco" meanings abandon the function that use ORB to get image keypoint, i don't think the ORB method is unable to find out keypoints, the fatal reason that i abandon ORB method is the time cost. ORB method maybe cost time twice as fast as Aruco. but you can see ORB can get more keypoints, this is the contradiction.


## Component

* RealTimePoseEstimation_WithAurcoDetect    -> Main Qt Project
* RealTimePoseEstimation_WithAurcoDetect_Data   -> Data Use

## Introduction
Before read, recommand you read the Opencv3 offical project [Real Time pose estimation of a textured object](http://docs.opencv.org/3.1.0/dc/d2c/tutorial_real_time_pose.html) and here is [Code](https://github.com/opencv/opencv/tree/master/samples/cpp/tutorial_code/calib3d/real_time_pose_estimation)

### registration ( `main_registration.cpp`)
the offical idea is build a connection between ORB keypoint and it's 3d Postion in world coordinate. Use this connection, the video frame can use ORB detect to get keypoint, thus obtained it's **3d Postion in world coordinate**, with the **2d position in Camera coordinate**, finally use `SolvePnP` method to get the object position estimate.

we replace the ORB keypoint with The four vertices of the Aruco matrix. Use Aurco detect can get the Aruco maker very quickly, so how can we get the connections between vertices of aruco matrix with its' 3d point in world coordinate?

The offcial code give us a solution to deal with it. At the begining of registration, we need the user to point the 8 vertices of this Cube, so we can get the **vertices 2d position in camera coordinate**, and we fill the **vertices 3d Postion in world coordinate** in `box.ply`. So, we can use these data to caculate the cube's position and rotaion with `SolvePnp`. Thus we can use the result to project four vertices of the Aruco matrix which is **2d position in camera coordinate** to **3d Postion in world coordinate** (`pnp_registration.backproject2DPoint(&mesh, point2d, point3d)`), so i get the connections, save it to `cookies_ORB.yml` 

### merge the regist file (`main_merge.cpp`)
Update at 2017.06.07
As you know, regist from one picture is not enough, because **Aruco cannot detect all marker in this cube**, we have to combine the regist result from multi-picture.

In this project, I regist 5 pictures manually, get 5 regist yml file. `cookies_Aruco_registrate_1.yml`, `cookies_Aruco_registrate_2.yml` ... And then use `main_merge.cpp`. So The vertices of each aruco marker square have multiple measurements, calculate the sum of the distances of each measurement coordinate to the other measured coordinates, then deleting the measurement coordinates with too much deviation.

finally get the average aruco matrix's **3d point in world coordinate**.

### detection in video (`main_detection.cpp`)
continue with above,we have got the connections between vertices of aruco matrix with its' **3d point in world coordinate**.

next is simple, detect the video per frame, get the four vertices of the Aruco matrix(meanings get the point's **2d position in camera coordinate**), find the map(Store the connection which introduced above), get the **3d Postion in world coordinate**, then, `SolvePnp` it!


ps.The stability of this method is heavily dependent on kalman filter, but I donnot know too much about kalman, so I ignored it.

## Show it
![](https://ws1.sinaimg.cn/mw690/bc1eaf88ly1fgcnhrgep8j20dp08njud.jpg)

Here is gif :
[gif-address](https://ws1.sinaimg.cn/mw690/bc1eaf88ly1fgcnc15zyig20ds08qe8b.gif)



 