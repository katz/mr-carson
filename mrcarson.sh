#!/bin/bash

# echo off
> /dev/null 2>&1

if [ $# -ne 4 ]; then
	echo "指定された引数は$#個です。実行するには4個の引数が必要です。" 1>&2
	echo "使い方: eth0を上限20Mbps、追加遅延10ms、パケットロス1%にする例" 1>&2
	echo "" 1>&2
	echo "$ sudo mrcarson.sh eth0 20Mbit 10ms 1%" 1>&2
	exit 1
fi

#echo on
set -x

###########################################################################################
# 引数で指定されたインターフェイスの全てのoutbound通信はクラス1:20とし、帯域制限やパケロスを適用する
# ただし、SSHトラフィックについてはクラス1:10にし、帯域制限やパケロスがかからないようにする
###########################################################################################

# まずは既存のqdiscをクリアする（フィルタやクラスもクリアされる）
sudo tc qdisc del dev $1 root

# 次にHTB(Hierarchy Token Bucket)を作成する
# とりあえずISPの上り・下りは最大1Gbpsまで出る想定でパラメータを設定しておく
sudo tc qdisc add dev $1 root handle 1: htb default 20
sudo tc class add dev $1 parent 1:  classid 1:1  htb rate 1000Mbit ceil 1000Mbit burst 10MB cburst 10MB
sudo tc class add dev $1 parent 1:1 classid 1:10 htb rate 1000Mbit ceil 1000Mbit burst 10MB cburst 10MB

# クラス1:10のトラフィックについてはそのままPFIFO(Packet limited First In, First Out queue)でそのまま送出する
sudo tc qdisc add dev $1 parent 1:10 handle 100: pfifo limit 1000

# SSHトラフィック（宛先または送出元ポートが22番）を識別するフィルタ
sudo tc filter add dev $1 protocol ip parent 1:0 prio 1 u32 match ip sport 22 0xffff flowid 1:10
sudo tc filter add dev $1 protocol ip parent 1:0 prio 1 u32 match ip dport 22 0xffff flowid 1:10


# <><><><><><><><><><><><><><><><><><><><><><><><>
# 帯域コントロール
# 『ceil 20Mbit』で上限20Mbpsになる。
# <><><><><><><><><><><><><><><><><><><><><><><><>
sudo tc class add dev $1 parent 1:1 classid 1:20 htb rate $2 ceil $2 burst 125kb cburst 125kb


# <><><><><><><><><><><><><><><><><><><><><><><><>
# パケロス、パケット遅延コントロール
# <><><><><><><><><><><><><><><><><><><><><><><><>
sudo tc qdisc add dev $1 parent 1:20 handle 200: netem delay $3 loss $4

