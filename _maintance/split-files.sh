#!/usr/bin/env bash

#split big commits, for rebase purposes
# base https://hisham.hm/2019/02/12/splitting-a-git-commit-into-one-commit-per-file/

message="$(git log --pretty=format:'%s' -n1)"
author="$(git log -n1 --format="%aN")"
atime="$(git log -n1 --format="%at")"
git_commit="git commit --date=$atime --author=$author"

#atime=$[$atime+1]

if [ `git status --porcelain --untracked-files=no | wc -l` = 0 ]
then
   git reset --soft HEAD^
fi

git status --porcelain --untracked-files=no | while read status file mm mfile
do
   echo $status $file

   if [ "$status" = "M" ]
   then
      git add $file
      $git_commit -n $file -m "$file: $message"
   elif [ "$status" = "A" ]
   then
      git add $file
      $git_commit -n $file -m "added $file: $message"
   elif [ "$status" = "D" ]
   then
      git rm $file
      $git_commit -n $file -m "removed $file: $message"
   elif [ "$status" = "R" ]
   then
      git add $file $mfile
      $git_commit -n $file $mfile -m "renamed $file -> $mfile: $message"
   else
      echo "unknown status $file"
   fi
done
