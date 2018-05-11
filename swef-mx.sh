#!/usr/bin/env bash
dig $1 MX | grep -A 1 -C 0 ';; ANSWER SECTION:' | tail -n 1 | awk '{print $6;}' | sed 's/.$//'
