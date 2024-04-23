#!/bin/bash

echo "a" | awk '
{
	for(i = 0; i < 1e6; i++) {
		for(j = 0; j < 98; j++) {
			printf $1
		}
		print
	}
}' > 100MB.txt
