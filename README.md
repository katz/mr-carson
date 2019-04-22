# Mr.Carson - an easy-to-use administrative interface for tc command

Linuxの `tc` コマンドをつかって帯域制限やパケットロスをエミュレーションする為のツールです。


## 使い方

eth0インターフェイスからのoutbound通信について、上限帯域20Mbps、追加遅延を10ms挿入、パケットロスを1%させるには次のように実行します。

```
$ sudo mrcarson.sh eth0 20Mbit 10ms 1%
```