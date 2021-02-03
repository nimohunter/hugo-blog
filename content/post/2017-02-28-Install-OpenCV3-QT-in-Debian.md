+++
author = "nimodai"
title = "Install OpenCv3 in Debain"
date = "2017-02-28"
description = ""
tags = [
    "OpenCV",
]
+++
About Opencv, this is a wonderful CV library. But for some reason, the installation isn't kindful for begenner.I try to use Visual Studio, but lots of Opencv DLL files makes me crazy. So I choose Debian platform, and Qt, which i feel more comfortable.

### 1. Prepare

We should install some dependencies.

##### Ubuntu/Debian:

```
ubuntu
sudo apt-get install qt5-default
apt-get install libgtk2.0-dev
apt-get install pkg-config
```

references: [first-example-code-error](http://answers.opencv.org/question/46755/first-example-code-error/)

##### CentOS

```
yum install cmake gcc gcc-c++ gtk+-devel gimp-devel gimp-devel-tools gimp-help-browser \
zlib-devel libtiff-devel libjpeg-devel libpng-devel gstreamer-devel \
libavc1394-devel libraw1394-devel libdc1394-devel \
jasper-devel jasper-utils swig python libtool nasm 
```

if you don not install these dependecies, maybe you will see this error:
```
OpenCV Error: Unspecified error (The function is not implemented. Rebuild the library with Windows, GTK+ 2.x or Carbon support. If you are on Ubuntu or Debian, install libgtk2.0-dev and pkg-config, then re-run cmake or configure script) in cvNamedWindow,...................
```
you have to remove all Opencv lib, and Reinstall all of them.

```
rm /usr/local/lib/libopencv*
rm -fr /usr/local/include/opencv
rm -fr /usr/local/include/opencv2
```

### 2. use cmake-gui

Maybe in your Linux, you have install cmake, but not include cmake-gui. Recommand you install cmake-gui to build opencv3.

1. Fill in Opencv3 Source Code, Download from Opencv office site. Choose the file to save build Code.
2. Click "Configure"
3. Choose "Unix MakeFiles" and "Use default native compilers", Click "Finish"
4. Search for " With_QT" "With_OPENCL" , if you need Mp4 Video decode, remember "USE_FFMPEG", but you have to install "ffmpeg" in step 1, if you need opencv_contrib, download it , and fill "OPENCV_EXTRA_MODULESPATH"
5. Click "Generate"

and then, change Directory which your saved build code,
```
make
make install
```


* The Opencv3 lib will install at "/usr/local/lib"
* C++ head file will install at /usr/local/include/opencv and opencv2
* help Document will install at /usr/local/share/opencv
* sample code will install at /usr/local/share/opencv

6. edit `opencv.conf`, add "/usr/local/lib" to `/etc/ld.so.conf.d/opencv.conf`
7. add `PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig  \
export PKG_CONFIG_PATH` to `/etc/bash.bashrc`

references: [Linux 下编译安装OpenCV](http://www.cnblogs.com/emouse/archive/2013/02/22/2922940.html)

### 3. Install QT
Download from Qt Office site.

### 4. Focus on .pro file
New a "Qt Console Application", and change the .pro to this:
```
QT += core
QT -= gui

CONFIG += c++11

TARGET = "Your Project Name"
CONFIG += console
CONFIG -= app_bundle
INCLUDEPATH += .
INCLUDEPATH += /usr/local/include/

LIBS += -L/usr/local/lib/ -I/usr/local/include -lopencv_core -lopencv_highgui -lopencv_imgproc -lopencv_aruco -lopencv_imgcodecs
# [!!!] sometime you should add this LIBS path include.

TEMPLATE = app

SOURCES += main.cpp
```

### 5. Test it!
your main.cpp
```
#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/aruco.hpp>
#include <strstream>
using namespace cv;
using namespace std;

int main()
{
    Mat img=imread("pic.jpg");
    imshow("show", img);
    waitKey();
    destroyAllWindows();
}
```
