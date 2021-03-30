+++
author = "nimodai"
title = "Talk-About-Go-Routine"
date = "2021-03-30"
description = ""
tags = [
    "go",
]
+++
goroutine 资料和内容很多，这里不用进行说明和讲解，只要知道go语言的核心在于 communicate by channel , rather than by share memory 就好了。这里记录遇到的一些小坑。

## 1. panic影响主线程

```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	fmt.Println("[main] routine start..")
	wg := sync.WaitGroup{}
	wg.Add(1)
	go func() {
		panicExample()
		wg.Done()
	}()
	wg.Wait()
	fmt.Println("[main] routine stop..")
}

func panicExample() {
	arr := make([]int, 0, 3)
	fmt.Println(arr[10])
}

```

返回结果：

```
[main] routine start..
panic: runtime error: index out of range [10] with length 3

goroutine 25 [running]:
main.panicExample()
        /Users/nimo/go/src/testGo/main.go:25 +0xd3
main.main.func1(0xc00044aa60)
        /Users/nimo/go/src/testGo/main.go:13 +0x25
created by main.main
        /Users/nimo/go/src/testGo/main.go:12 +0xc7

Process finished with exit code 2
```



这里使用 index out of range 错误，直接导致了整体线程的崩溃。 当然，如果这里是gin，也是一样的，这是后台应用所无法接受的。所以一般需要做一些recover的封装。

```go

func main() {
	fmt.Println("[main] routine start..")
	wg := sync.WaitGroup{}
	wg.Add(1)
	go func() {
		defer func() {
			if r := recover(); r != nil {
				fmt.Println(time.Now().String()+gconv.String(r)+string(debug.Stack()), errors.New("go routine error"))
			}
			wg.Done()
		}()
		panicExample()
	}()
	wg.Wait()
	fmt.Println("[main] routine stop..")
}
```

## 2. goroutine 不能直接使用Loop variable的问题（Loop variable 'XXX' captured by func literal ）

```go
package main

import (
	"errors"
	"fmt"
	"runtime/debug"
	"sync"
	"time"

	"github.com/gogf/gf/util/gconv"
)

func main() {
	animals := []string{"cat", "dog", "chicken"}
	wg := sync.WaitGroup{}
	for _, animal := range animals {
		fmt.Println("for loop animal:" + animal)
		wg.Add(1)
		go func() {
			defer func() {
				if r := recover(); r != nil {
					fmt.Println(time.Now().String()+gconv.String(r)+string(debug.Stack()), errors.New("go routine error"))
				}
			}()
			defer wg.Done()
			fmt.Println("go routine  animal:" + animal)
		}()
	}
	wg.Wait()
	fmt.Println("[main] stop")
}

```

输出结果为:

```
for loop animal:cat
for loop animal:dog
for loop animal:chicken
go routine  animal:chicken
go routine  animal:chicken
go routine  animal:chicken
[main] stop
```

结果是错误的，go运训goroutine引用外部的变量。这个没有问题，有问题的在于主线程和routine的启动时间不同， 主线程的循环跑完了之后、各个routine才刚刚开始跑，所以拿到的结果是最后的结果。

所以这里需要注意，传递给routine的变量必须是不能变的。至少在主线程结束前不能变。

对于这种情况，解决问题有两种：一种是单独赋值：

```go
func main() {
	animals := []string{"cat", "dog", "chicken"}
	wg := sync.WaitGroup{}
	for _, animal := range animals {
		fmt.Println("for loop animal:" + animal)
		wg.Add(1)
		animal0 := animal
		go func() {
			defer func() {
				if r := recover(); r != nil {
					fmt.Println(time.Now().String()+gconv.String(r)+string(debug.Stack()), errors.New("go routine error"))
				}
			}()
			defer wg.Done()
			fmt.Println("go routine  animal:" + animal0)
		}()
	}
	wg.Wait()
	fmt.Println("[main] stop")
}
```

另一种是传递参数

```go
c main() {
	animals := []string{"cat", "dog", "chicken"}
	wg := sync.WaitGroup{}
	for _, animal := range animals {
		fmt.Println("for loop animal:" + animal)
		wg.Add(1)
		go func(animalInner string) {
			defer func() {
				if r := recover(); r != nil {
					fmt.Println(time.Now().String()+gconv.String(r)+string(debug.Stack()), errors.New("go routine error"))
				}
			}()
			defer wg.Done()
			fmt.Println("go routine  animal:" + animalInner)
		}(animal)
	}
	wg.Wait()
	fmt.Println("[main] stop")
}
```



