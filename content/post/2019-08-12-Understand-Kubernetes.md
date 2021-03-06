+++
author = "nimodai"
title = "Understand-Kubernetes"
date = "2019-08-12"
description = ""
tags = [
    "Kubernetes",
]
+++

> 这是一篇不那么正经的Kubernetes讲解，并不对实际的API进行讲解，只描述其Kubernetes的基本特点和核心功能。

Kubernetes 是在CNCF (Cloud Native Computing Foundation) 牵头，由社区完善的大规模容器编排处理平台。根据近几年的发展，基本上成为了容器编排平台的标准地位。从大多数软件开发者的角度来说，Kubernetes解决的事代码 push commit 之后的所有事项，从 CI/CD，到发布运维，到升级回滚。

## Kubernetes 特点

个人认为 Kubernetes 主要设计特点在于对用户十分友好的声明式API以及实现声明式API的控制器，其次是容器编排能力与足够开放的CRI, CSI, CNI。

### 声明式API以及控制器

声明式API相对应的是命令式API。Kubernetes做到了所声明即所得，意味着用户利用yaml文件声明的某种API的描述，kubernetes能够时刻保证现状和用户声明的一致，如果发生变化，kubernetes将试图进行一系列自动的操作来维持一致性。所以Kubernetes的高层API是相对抽象的，更多的从业务出发，更多的使用户的操作更直观和简单。

为了维持这种声明式的结果就需要不断地检查自身的现状，这就是调协(Reconcile)，就是控制器主要功能，用来保证声明的结果实时是正确的。

而基于Kubernetes的开发基本就围绕在 Custom Resource Define 与 Custom Controller. 建设更高层的API，满足业务需求。

### 容器编排
容器编排是Kubernetes的核心能力，将不同的Pod放在合适的Node上，并在需要的时候进行腾挪。这里正在进行重构，目前的 Default Scheduler 可能并不能满足复杂的业务发展和需求。

默认调度器有两个控制循环。一个是Informer Path，用来监听Etcd中Pod，Node，Service等与调度相关的API的变化，并将待调度的事件放入Priority Queue中。另一个是 Scheduling Path。从Priority Queue取出相关事件，例如
新建Pod。经过Predicate来检查过滤Node，然后在符合条件的Node中进行Priority操作进行打分，分数最高的Node接收该Pod。

### CNI(Container Network Interface)
Kubernetes默认所有的容器都是三层联通的。但是在实际中，如果不做操作，宿主机的容器只能和其他的宿主机通信，无法跟其他宿主机的容器进行通信。

Kubernetes并不解决跨容器通信问题，只是通过CNI插件来完成这个问题。最常见的有两种实现方式：

1. Calico 将容器的ip通过BGP来维护一个路由表，让所有跨主机通信知道某个容器的ip应该送往哪个宿主机。二层不通的情况下使用IPIP封装。
2. Flannel + VxLan 通过二次封包和隧道进行通信，同样也需要容器ip和宿主机ip关系。

> 其中容器ip和宿主机ip关系存储在Etcd中，Etcd另一个存储就是Pod Node 等API的数据。

### CRI(Container Runtime Interface)
Kubernetes 最初的底层容器使用的是docker，但是因为CoreOs公司的rkt容器等历史原因,Kubernetes将对容器的操作抽象出来，不再对docker进行直接操作。保证下层无论是哪种容器化技术，kubernetes都能够通过CRI进行操作。

例如 kata Container 与 gVisor等。

### CSI(Containner Storage Interface)
Kubernetes 本身有 in-tree 的调用存储服务的方式，但是这种方式需要存储提供者将代码并入Kubernetes的代码中，随着版本同时发布，这种和Kubernetes耦合的方式是不合理的。
所以Kubernetes提供了两种Storage Plugin，FlexVolume 和 CSI。

FlexVolume 简单的将 mount attach 等功能相应做成 executable file 放入K8S中，提供了简单的自定义能力，由宿主机调用从而进行 attach 和 mount，provision 功能依然不支持。这种方式局限性比较大，首先是需要在宿主机安装一些必要的辅助插件，其次是FlxeVolume的每一次对插件可执行文件的调用都是一次独立调用，没有ctx。

CSI 试图建立行业标准接口，将 Provision 以及 Kubernetes 的 Attach 和 Mount 功能全部抽离，形成单独的组件External Component (Driver Registrar, External Provisioner, External Attacher)。这部分都是K8S的部分，将具体实现扔出到CSI插件中去。