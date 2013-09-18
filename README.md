First, create a new repo on github. and clone e.g

    git clone myspecialisedresource
    cd myspecialisedresource

Add a README.md or some other file and commit and push

    git add .
    git commit -m 'first commit'
    git push

Now create a new 'remote' (i.e. a pointer to a remote repo, in this case the skeleton-resource code)

    git remote add skeletonrepo git@github.com:horizon-institute/dataware.resource-skeleton
    git fetch skeletonrepo

Create a remote tracking branch:

    git branch --track skeleton skeletonrepo/master

Check that it looks ok:

    git checkout skeleton
    ls

If all is fine, merge the skeleton code into the master branch:

    git checkout master
    git merge skeleton

At this point you have the master branch, which is where you can add code that specialises the resource, and the skeleton branch which can be used to pull/push bugfixes.

If you subsequently want to make a bugfix, you simply:

    git checkout skeleton

make the fixes

then

    git add .
    git commit -m 'my bugfix on the tracking branch'

and to push the change directly onto the master branch

    git push skeletonrepo skeleton:master

You'll then need to merge the changes into the master branch:

    git checkout master
    git merge skeleton
