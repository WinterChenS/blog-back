#!/bin/bash
git pull origin hexo  &&
hexo clean && hexo g -d && 
echo "------------------------------------------------------" &&
echo "hexo build successfully!" &&
echo "------------------------------------------------------" 
