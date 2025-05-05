#!/bin/sh


echo `shasum "$1" | cut -d ' ' -f 1` || exit 1;
