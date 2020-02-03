#!/usr/bin/env bash

set -e

DIR=$(dirname ${BASH_SOURCE[0]})
GPS=$(realpath $DIR/git-post-squash)
TESTDIR=$DIR/_test

rm -rf $TESTDIR
git init $TESTDIR
GIT="git --no-pager -C $TESTDIR"

$GIT config user.email "test@example.com"
$GIT config user.name "Test user"

function mod () {
  echo $1 > $TESTDIR/foo
  $GIT add foo
  $GIT commit -q -m "Change $1"
}

# Setup
mod 1
mod 2
$GIT checkout -q -b featureA
mod 3
$GIT checkout -q -b featureB
mod 4
$GIT checkout -q master
mod 5
$GIT checkout -q featureA
mod 6
$GIT merge -q -X ours master -m 'master → featureA'
# $GIT log --oneline --graph


# The first squash merge
$GIT checkout master
$GIT merge -q --squash featureA
$GIT commit -q -m 'squash featureA → master'

cmp -s \
  <($GIT show -s --pretty='%T' master) \
  <($GIT show -s --pretty='%T' featureA) \
  || { echo "Test setup broken: Trees not identical"; exit 1; }


# more changes on master and featureA
mod 7
$GIT checkout -q featureA
mod 8
$GIT merge -q -X ours master -m 'master → featureA'

# The second squash merge

$GIT checkout master
$GIT merge -q --squash featureA
$GIT commit -q -m 'squash featureA → master'
expected_squash_merge=$($GIT show -s --pretty='%H' HEAD)

cmp -s \
  <($GIT show -s --pretty='%T' master) \
  <($GIT show -s --pretty='%T' featureA) \
  || { echo "Test setup broken: Trees not identical"; exit 1; }

# More commits on master
mod 9
mod 10


# The post-squash merge

$GIT checkout -q featureB
$GIT merge -s ours -q featureA -m 'featureA → featureB'

$GIT checkout featureB
mod 11
pre_merge=$($GIT show -s --pretty='%H' HEAD)

( cd $TESTDIR;  $GPS master )
$GIT show HEAD
cmp -s \
  <(echo "$pre_merge $expected_squash_merge") \
  <($GIT show -s --pretty='%P' featureB) \
  || { echo "Test broken: unexpected parents"; exit 1; }


$GIT log --oneline --graph --all
