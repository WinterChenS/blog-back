#!/bin/bash
git pull origin master  &&
hexo clean && hexo g -d && 
echo "------------------------------------------------------" &&
echo "hexo build successfully!" &&
echo "------------------------------------------------------" 
