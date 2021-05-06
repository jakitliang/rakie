# Rakie

> Rakie is lucky and cakie~

## Intro

Rakie is a high performance event-driven server and client framework.

It works at any platform and simple delpoyment.

## Requirements

* Ruby 2.5+
* Linux 3.x+ / macOS 10.10+

## Perfomance

* System: `macOS 11.2.3`
* Protocol: `HTTP`
* Testing tool: `siege`
* Command: `siege -r 1000 -c 200 -q -b [url]`

| Threads | Trans | Elap Time | Data Trans | Resp Time | Trans Rate | Throughput | Concurrent | OKAY | Failed |
| ------- | ----- | --------- | ---------- | --------- | ---------- | ---------- | ---------- | ---- | ------ |
| 1 single thread | 200000 | 24.51 | 7 | 0.02 | 8159.93 | 0.29 | 199.70 | 200000 | 0 |
| Multithread (4) | 200000 | 15.67 | 7 | 0.02 | 12763.24 | 0.45 | 198.55 | 200000 | 0 |
| Multithread (8) | 200000 | 13.32 | 7 | 0.01 | 15015.02 | 0.53 | 198.22 | 200000 | 0 |

## Notice

Project is under construction.

Debug log info is muted by default.

Setting `Rakie::Log.level` to change log level.
