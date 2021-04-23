#!/bin/sh
cd /Users/nimo/hugo-web
hugo
tar -jcvf public.tar.bz2 public
scp public.tar.bz2 root@42.192.226.244:/root/public.tar.bz2