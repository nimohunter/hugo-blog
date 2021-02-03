+++
author = "nimodai"
title = "SolvePnP in 5 Methods"
date = "2017-03-21"
description = ""
tags = [
    "OpenCV",
]
+++
#### Before Begin
SolvePnP , Finds an object pose from 3D-2D point correspondences., which is the method that rebuild 3D position from 2D picture.

We DO NOT Care about the how to use SolvePnP, we try to understand the inner meaning of SolvePnP, and the 5 methods.

#### SolvePnP Methods and Paper table:


|  SolvePnP Methods  |                               Reference Paper                               | year |
|:------------------:|:---------------------------------------------------------------------------:|:----:|:-----:|
| SOLVEPNP_ITERATIVE |              Original based on Levenberg-Marquardt optimization             |      |       |
|    SOLVEPNP_EPNP   |          EPnP: Efficient Perspective-n-Point Camera Pose Estimation         | 2008 |
|    SOLVEPNP_P3P    |   Complete Solution Classification for the Perspective-Three-Point Problem  | 2003 |
|    SOLVEPNP_DLS    |                 A Direct Least-Squares (DLS) Method for PnP                 | 2011 |
|    SOLVEPNP_UPNP   | Exhaustive Linearization for Robust Camera Pose and Focal Length Estimation | 2013 |


Methods for solving a PnP problem:
-   **SOLVEPNP_ITERATIVE** Iterative method is based on Levenberg-Marquardt optimization. In
this case the function finds such a pose that minimizes reprojection error, that is the sum
of squared distances between the observed projections imagePoints and the projected (using
projectPoints ) objectPoints .
-   **SOLVEPNP_P3P** Method is based on the paper of X.S. Gao, X.-R. Hou, J. Tang, H.-F. Chang
"Complete Solution Classification for the Perspective-Three-Point Problem". In this case the
function requires exactly four object and image points.
-   **SOLVEPNP_EPNP** Method has been introduced by F.Moreno-Noguer, V.Lepetit and P.Fua in the paper "EPnP: Efficient Perspective-n-Point Camera Pose Estimation".
-   **SOLVEPNP_DLS** Method is based on the paper of Joel A. Hesch and Stergios I. Roumeliotis.
"A Direct Least-Squares (DLS) Method for PnP".
-   **SOLVEPNP_UPNP** Method is based on the paper of A.Penate-Sanchez, J.Andrade-Cetto,
F.Moreno-Noguer. "Exhaustive Linearization for Robust Camera Pose and Focal Length
Estimation". In this case the function also estimates the parameters \f$f_x\f$ and \f$f_y\f$
assuming that both have the same value. Then the cameraMatrix is updated with the estimated
focal length.

---

### 1. SOLVEPNP_ITERATIVE
Accroding to `solvepnp.cpp`:

```
else if (flags == SOLVEPNP_ITERATIVE)
{
    CvMat c_objectPoints = opoints, c_imagePoints = ipoints;
    CvMat c_cameraMatrix = cameraMatrix, c_distCoeffs = distCoeffs;
    CvMat c_rvec = rvec, c_tvec = tvec;
    cvFindExtrinsicCameraParams2(&c_objectPoints, &c_imagePoints, &c_cameraMatrix,
                                 c_distCoeffs.rows*c_distCoeffs.cols ? &c_distCoeffs : 0,
                                 &c_rvec, &c_tvec, useExtrinsicGuess );
    result = true;
}
```
Which meanings this Method use the function `cvFindExtrinsicCameraParams2` in `calibration.cpp`.

#### About cvFindExtrinsicCameraParams2

In this moment, should reference [offical calib3d](http://docs.opencv.org/3.1.0/d9/d0c/group__calib3d.html). In Detailed Desciption, focus on the perspective transformation.

![original-photo](http://www.opencv.org.cn/opencvdoc/2.3.2/html/_images/math/50a3464c85a412907d91fd8895108ff692eb8d08.png)

* (X, Y, Z) are the coordinates of a 3D point in the world coordinate space
* (R t) is the Camera's Rotation and Position, which is what we need to know
* fx, fy, cx, cy is the Camera's intrinsic
* s is Focal length
* u v are the coordinates of the projection point in pixels(picture)

or can use this table:

![other-photo](http://docs.opencv.org/2.4/_images/math/f51a5ba02487486308c29bef720f3186d18abac6.png)

In `cvFindExtrinsicCameraParams2`, you can get Camera extrinsic from intrinsic, camera intrinsic matrix and distortion coefficients.

Camera extrinsic is Camera's Postion and Rotation, in the other word, if the Camera is static, then can get the Object's Position and Rotation, but the output is reversed. 

#### How to Calc cvFindExtrinsicCameraParams2

Back to `cvFindExtrinsicCameraParams2`, this function use DLT(Direct Linear Transform)  algorithm solve it, and refine extrinsic parameters using Levenberg-Marquardt algorithm.

![DLT](http://rosclub.cn/data/attachment/portal/201612/01/230812wss38nmn2qs08k1f.jpg)

Then, use Gaussion-Newton minimize the reprojection error.


### 2. SOLVEPNP_P3P
First, we have to know, the P, A, B, C must be Non-coplanar. 

![P3P_1](https://ws1.sinaimg.cn/large/bc1eaf88ly1febvzy7u9sj20m70ez4cc.jpg)

use the law of cosines, we can know:


![\begin{align*}Y^2+Z^2-2YZ\cos\alpha={a}'^2\\X^2+Z^2-2XZ\cos\beta={b}'^2\\X^2+Y^2-2XY\cos\gamma={c}'^2\\\end{align*}](https://latex.codecogs.com/png.latex?%5Cinline%20%5Cbegin%7Balign*%7DY%5E2&plus;Z%5E2-2YZ%5Ccos%5Calpha%3D%7Ba%7D%27%5E2%5C%5CX%5E2&plus;Z%5E2-2XZ%5Ccos%5Cbeta%3D%7Bb%7D%27%5E2%5C%5CX%5E2&plus;Y%5E2-2XY%5Ccos%5Cgamma%3D%7Bc%7D%27%5E2%5C%5C%5Cend%7Balign*%7D)

![P3P_2](https://ws1.sinaimg.cn/large/bc1eaf88ly1febwi6tc88j20m60f4dth.jpg)

Final, Fomulation(13), x can get 4 possible answer. So, use the 4th point to determind the best answer.

![P3P_3](https://ws1.sinaimg.cn/large/bc1eaf88ly1febwsm7vpjj20m60eh49u.jpg)




### 3. SOLVEPNP_EPNP
Reference: 
1. [关于使用SVD分解方法求解AX=0方程的一点说明](http://www.voidcn.com/blog/zhyh1435589631/article/p-6512659.html)
2. [Document of classbook](http://course.shufe.edu.cn/jpkc/jcjx/gdds/exs/ex11.pdf)
3. [PnP算法简介与代码解析-柴政](http://rosclub.cn/post-566.html)
4. [SolvePnp Algorithm(Chinese Version)](http://www.cnblogs.com/jian-li/p/5689122.html) and Paper.

Key Word: SVD(Singular Value Decomposition)

#### 3.1 Mx = 0
First, you should understand that every point can be present by four base point in 3D space. In theory, the control points(four base points) can be chosen arbitrarily, However, in practice, found that the stability of the paper's method is increased by taking the centroid of the reference points as one, and to select the rest in such a way that they form a basis aligned with the principal directions.

First, look at this basic fomulation: P^w meaning points in world coordinate, meanwhile P^c meaning points in camera coordinate. P^c is what we determind first, so every point can be present by four base point.

![p_i^w=\sum_{j=1}^4\alpha_{ij}c_j^w, \quad with \sum_{j=1}^4\alpha_{ij}=1](https://latex.codecogs.com/gif.latex?p_i^w=\sum_{j=1}^4\alpha_{ij}c_j^w,&space;\quad&space;with&space;\sum_{j=1}^4\alpha_{ij}=1)

![p_i^c=\sum_{j=1}^4\alpha_{ij}c_j^c, \quad with \sum_{j=1}^4\alpha_{ij}=1 ](https://latex.codecogs.com/gif.latex?p_i^c=\sum_{j=1}^4\alpha_{ij}c_j^c,&space;\quad&space;with&space;\sum_{j=1}^4\alpha_{ij}=1)

![\omega_i \begin{bmatrix} U_i \\ V_i \\ 1 \end{bmatrix} = \begin{bmatrix} R & T  \end{bmatrix} \begin{bmatrix} X \\ Y \\ Z \\ 1 \end{bmatrix}](http://latex.codecogs.com/gif.latex?\omega_i&space;\begin{bmatrix}&space;U_i&space;\\&space;V_i&space;\\&space;1&space;\end{bmatrix}&space;=&space;\begin{bmatrix}&space;R&space;&&space;T&space;\end{bmatrix}&space;\begin{bmatrix}&space;X&space;\\&space;Y&space;\\&space;Z&space;\\&space;1&space;\end{bmatrix})

in this case,

![\begin{bmatrix} R & T  \end{bmatrix} \begin{bmatrix} X \\ Y \\ Z \\ 1 \end{bmatrix}](http://latex.codecogs.com/gif.latex?\begin{bmatrix}&space;R&space;&&space;T&space;\end{bmatrix}&space;\begin{bmatrix}&space;X&space;\\&space;Y&space;\\&space;Z&space;\\&space;1&space;\end{bmatrix})  

is matrix multiplication, Present the object point transform from World coordinate to Camera coordinate, meanings the Object position in Camera view, and this can be present by four base points.

![ \sum_{j=1}^4a_{ij}C^c_j = \begin{bmatrix} R & T  \end{bmatrix} \begin{bmatrix} X \\ Y \\ Z \\ 1 \end{bmatrix}](https://latex.codecogs.com/gif.latex?\sum_{j=1}^4a_{ij}C^c_j&space;=&space;\begin{bmatrix}&space;R&space;&&space;T&space;\end{bmatrix}&space;\begin{bmatrix}&space;X&space;\\&space;Y&space;\\&space;Z&space;\\&space;1&space;\end{bmatrix})

so,

![\omega_i \begin{bmatrix} U_i \\ V_i \\ 1 \end{bmatrix} = \begin{bmatrix} R & T  \end{bmatrix} \begin{bmatrix} X \\ Y \\ Z \\ 1 \end{bmatrix} = Ap_i^c = A\sum_{j=1}^4a_{ij}C^c_j](http://latex.codecogs.com/gif.latex?\omega_i&space;\begin{bmatrix}&space;U_i&space;\\&space;V_i&space;\\&space;1&space;\end{bmatrix}&space;=&space;\begin{bmatrix}&space;R&space;&&space;T&space;\end{bmatrix}&space;\begin{bmatrix}&space;X&space;\\&space;Y&space;\\&space;Z&space;\\&space;1&space;\end{bmatrix}&space;=&space;Ap_i^c&space;=&space;A\sum_{j=1}^4a_{ij}C^c_j)

and, from the last row, you can find 

![\omega_i = \sum_{j=1}^4a_{ij}z^c_j](http://latex.codecogs.com/gif.latex?\omega_i&space;=&space;\sum_{j=1}^4a_{ij}z^c_j)

so, this matrix can be,

![\sum_{j=1}^4\alpha_{ij}f_ux^c_j+\alpha_{ij}(u_c-u_i)z^c_j=0 ](http://latex.codecogs.com/gif.latex?\sum_{j=1}^4\alpha_{ij}f_ux^c_j&plus;\alpha_{ij}(u_c-u_i)z^c_j=0)

![\sum_{j=1}^4\alpha_{ij}f_v y^c_j+\alpha_{ij}(v_c-v_i)z^c_j=0](http://latex.codecogs.com/gif.latex?\sum_{j=1}^4\alpha_{ij}f_v&space;y^c_j&plus;\alpha_{ij}(v_c-v_i)z^c_j=0)

so, every point have two formulation, so, seems like, 

![[M][X] = 0](http://latex.codecogs.com/gif.latex?[M][X]&space;=&space;0)

[M] is [2n*12] Matrix, [X] is [12\*1]  (n meanings the number of Object Points, 12-vector unknow is these four basic points' position in Camera View.)

Then, the Question is how to min the Mx. Simple say, The least squares solution is the eigenvector corresponding to the smallest singular value of M ^ TM (最小二乘解就是 M^TM的最小的奇异值所对应的特征向量)。This can get X, meanings C_j^w, base points in Camera coordinate.

Because of the noise, we can not just get the x from Mx=0, Although we can calculate the x by Least Squares, which can get answer by M^TMx = M^T0, but we can not only focus the min eigenvector in SVD, we need the 2nd min eigenvector and more .

So we need do SVD from A^TA, get the Vj(j is the last 4 column) 

Reference: [SVD-PPT-Chinese](http://www.doc88.com/p-7317011843934.html)

#### 3.2 L * beta=P

Focus on X, we know that the solution is smallest singular value, but with the noise, we have to consider penultimate sigular value and others, so consider the follow formulation.

![X = \sum_{k = 1}^N\beta_kV_k](https://latex.codecogs.com/gif.latex?X&space;=&space;\sum_{k&space;=&space;1}^N\beta_kV_k)

With the paper, we know that the N can be 1,2,3 and 4. When f is small, meanings we choose a small focal length, M^TM have only one zero eigenvalue, however, as the focal length increases and camera becomes closer to being orthograhic, all four smallest eigenvalues approach zero, so the N can be 4. Furthermore, if the correspondences are noisy, the smallest of them will be tiny but not strictly equal to zero.

if We do not have noise, we can know the N = 1, and the X is the vector which the eigenvalue is zero. but in natural, the noise and the Object points can not be precise, so we have to make N to be 3 or 4.

so we have to solve beta_k. The stratage is whether in World coordinate or Camera coordinate, the length between two points is static, so,

![\Vert c_i^c - c_j^c\Vert^2=\Vert c_i^w - c_j^w\Vert^2](https://latex.codecogs.com/gif.latex?\Vert&space;c_i^c&space;-&space;c_j^c\Vert^2=\Vert&space;c_i^w&space;-&space;c_j^w\Vert^2)


![if N = 1, \Vert \beta \rm{v}^{[i]}-\beta \rm{v}^{[j]}\Vert^2=\Vert c_i^w - c_j^w\Vert^2](https://latex.codecogs.com/gif.latex?if&space;N&space;=&space;1,&space;\Vert&space;\beta&space;\rm{v}^{[i]}-\beta&space;\rm{v}^{[j]}\Vert^2=\Vert&space;c_i^w&space;-&space;c_j^w\Vert^2)

...

![EPnP-Solve_beta](http://rosclub.cn/data/attachment/portal/201612/01/230806q5fqqfzedkkqqsc5.jpg)



#### 3.3 GN(Gaussion Newton iteration)
Iteration beta, min the cost


![Error(\beta )=\sum _{(i,j) i < j}(\Vert c_i^c - c_j^c\Vert^2-\Vert c_i^w - c_j^w\Vert^2)](https://latex.codecogs.com/png.latex?%5Cinline%20Error%28%5Cbeta%20%29%3D%5Csum%20_%7B%28i%2Cj%29%20i%20%3C%20j%7D%28%5CVert%20c_i%5Ec%20-%20c_j%5Ec%5CVert%5E2-%5CVert%20c_i%5Ew%20-%20c_j%5Ew%5CVert%5E2%29)

have to focus on Jacobi iteration.

![Jacobi](https://wikimedia.org/api/rest_v1/media/math/render/svg/9fc2ba24e56db5f23265cc45aa7243de4d49e86f)

in Newton method:

![first](http://latex.codecogs.com/gif.latex?g(x)%7b%5capprox%7dg(%7bx_k%7d)%2bg%27(%7bx_k%7d)(x-%7bx_k%7d))

![second](http://latex.codecogs.com/gif.latex?g(%7bx_k%7d)%2bg%27(%7bx_k%7d)(x-%7bx_k%7d)%3d0)

![Thrid](http://latex.codecogs.com/gif.latex?%7bx_%7bk%2b1%7d%7d%3d%7bx_k%7d-%5cfrac%7b1%7d%7b%7bg%27(%7bx_k%7d)%7d%7dg(%7bx_k%7d))

so, in our Error:

![\beta_{k+1}=\beta_k-\frac{1}{J_f(\beta_k)}E(\beta_k)](https://latex.codecogs.com/png.latex?%5Cinline%20%5Cbeta_%7Bk&plus;1%7D%3D%5Cbeta_k-%5Cfrac%7B1%7D%7BJ_f%28%5Cbeta_k%29%7DE%28%5Cbeta_k%29)


in Picture, this formulation is :

![J(\beta_0)\Delta\beta=-E(\beta_0)](https://latex.codecogs.com/png.latex?%5Cinline%20J%28%5Cbeta_0%29%5CDelta%5Cbeta%3D-E%28%5Cbeta_0%29)

like this:

![Epnp-Gn](http://rosclub.cn/data/attachment/portal/201612/01/230808yqzlbl11qlkkcqk5.jpg)



#### 3.4 Recover 3d points in camera coordinate

After GN, we can get the best _beta, so we can get the best P^c , with P^w, we can get R and t.

![X = \sum_{k = 1}^N\beta_kV_k](https://latex.codecogs.com/gif.latex?X&space;=&space;\sum_{k&space;=&space;1}^N\beta_kV_k)


![p_i^c=\sum _{j=1}^4\alpha _{ij}c_j^c](https://latex.codecogs.com/png.latex?%5Cinline%20p_i%5Ec%3D%5Csum%20_%7Bj%3D1%7D%5E4%5Calpha%20_%7Bij%7Dc_j%5Ec)


#### 3.5 Conclusion
we can use EPnP get the R and t, then use SOLVEPNP_ITERATIVE GN do the last optimize.

![](https://ws1.sinaimg.cn/large/bc1eaf88ly1febnta7r76j20m30ec15p.jpg)


### 4. SOLVEPNP_DLS
todo
### 5. SOLVEPNP_UPNP
UPnp is similar with EPnP, but UPnP do not know the matrix of intrinsic parameters, eg.(cx,cy) is a principal point that is usually at the image center ,fx,fy are the focal lengths expressed in pixel units.

in general, caculate the

![C_j^c=\begin{bmatrix}X_j^c\\Y_j^c\\Z_j^c\end{bmatrix}=\sum_{k=1}^N\begin{bmatrix}\beta_kV_{k,x}^j\\\beta_kV_{k,y}^j\\f\beta_kV_{k,z}^j\end{bmatrix}](https://latex.codecogs.com/gif.latex?%5Cinline%20C_j%5Ec%3D%5Cbegin%7Bbmatrix%7DX_j%5Ec%5C%5CY_j%5Ec%5C%5CZ_j%5Ec%5Cend%7Bbmatrix%7D%3D%5Csum_%7Bk%3D1%7D%5EN%5Cbegin%7Bbmatrix%7D%5Cbeta_kV_%7Bk%2Cx%7D%5Ej%5C%5C%5Cbeta_kV_%7Bk%2Cy%7D%5Ej%5C%5Cf%5Cbeta_kV_%7Bk%2Cz%7D%5Ej%5Cend%7Bbmatrix%7D)

in this case, N can be 1 or 2, sometimes, the with little Object point and too much noise, N have to be 3, but it will take much more time. 

![UPnP](https://ws1.sinaimg.cn/large/bc1eaf88ly1febzs4ef57j20m60ezdst.jpg)


## Conclusion

![](https://ws1.sinaimg.cn/large/bc1eaf88ly1fehfx5b2mtj20lq0emjxy.jpg)