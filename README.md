git post-squash
===============

TL;DR: Run

    git post-squash master

on branch `B` that includes `A`, after `A` has been squash-merged into
`master`.


Installation
------------

Just add this directory to your `PATH`, or copy or symlink `git-post-squash`
into a directory that is on your `PATH`.

What is a squash merge?
-----------------------

One popular workflow involving Git and Github is a squash-merge based workflow:
You develop your feature on a feature branch (say `featureA`), adding commits
as you go, possibly merging from master a few times:


    M1 ─ M2 ─────────── M3 ────── M4            (master)
           ╲              ╲
            A1 ─ A2 ─ A3 ─ A4 ─ A5              (featureA)

When the feature is ready, you merge `master` into `featureA` a last time (e.g.
to check on your CI infrastructure that this merge does not break the build):

    M1 ─ M2 ─────────── M3 ────── M4            (master)
           ╲              ╲         ╲
            A1 ─ A2 ─ A3 ─ A4 ─ A5 ─ A6         (featureA)

and now you do a squash merge (or use Github’s green “Squash merge” button, or
mergify.io’s squash merge action). The result is a new commit `M5` on `master`
that contains all the changes from `featureA`:

    M1 ─ M2 ─────────── M3 ────── M4 ─ M5       (master)
           ╲              ╲         ╲
            A1 ─ A2 ─ A3 ─ A4 ─ A5 ─ A6         (featureA)

Note that there is no line from `A6` to `M5`. This means that the git history
of `master` is clean, and does not contain the usually boring and unhelpful
history of how `featureA` came to be; no “fix typo” commits, no “merge master
into featureA” commit.

But the downside is that, as far as git is concerned, this commit is totally
unrelated to the `featureA` branch. This is not a problem as long as `featureA`
lives on its own. But it becomes a problem if there are feature branches
building off featureA:

What is the problem with squash merge?
--------------------------------------

Consider the situation above, but add `featureB` to the mix, a feature branch that was created off `featureA`:


    M1 ─ M2 ─────────── M3 ────── M4 ── M5      (master)
           ╲              ╲         ╲
            A1 ─ A2 ─ A3 ─ A4 ─ A5 ─ A6         (featureA)
                   ╲         ╲
                    B1 ────── B2 ─ B3           (featureB)

We now want to bring the latest changes from `featureA` and `master` into
`featureB`. Merging `featureA` into `featureB` is straight-forward:


    M1 ─ M2 ─────────── M3 ────── M4 ── M5      (master)
           ╲              ╲         ╲
            A1 ─ A2 ─ A3 ─ A4 ─ A5 ─ A6         (featureA)
                   ╲         ╲         ╲
                    B1 ────── B2 ─ B3 ─ B4      (featureB)

But if we run `git merge master` now, we are likely running into very
unfortunate git conflicts. Because to git, `M5` is unrelated to `featureA`, it
does not know that all the changes already have been merged into `featureB`
when we created the merge commit `B4`!

But we _know_ that `M5` contains nothing that isn’t already in `featureB`,
because `M5` was a squash commit of `A6`.

The manual way of resolving this is to run

    git merge -s ours master

which tells git: Pretend that we merged `master` into this, but don’t actually
touch any of the files, everything on the current branch is already in the form
we want. This way, we get


    M1 ─ M2 ─────────── M3 ────── M4 ── M5      (master)
           ╲              ╲         ╲     ╲
            A1 ─ A2 ─ A3 ─ A4 ─ A5 ─ A6    ╲    (featureA)
                   ╲         ╲         ╲    ╲
                    B1 ────── B2 ─ B3 ─ B4 ─ B5 (featureB)


Note: `git merge -s ours` is _not_ the same as the `git merge -X ours`! See the
manpage for `git merge` for details.

How does git-post-squash help?
------------------------------

While the manual way works, one needs to be careful: If `master` has progressed
further, or if `featureA` was not fully up-to-date before the squash merge,
using  `git merge -s ours` will easily and silently undo changes that were
already committed to master.

So instead run

    git post-squash master

which will do `git merge -s ours`, but it will

 * find the right commit on `master` to use (it may not be the latest) and
 * double-check that nothing is lost.

It does so by picking the latest commit on `master` that _has the same tree_ as
some commit on the current branch that is not yet on `master`.

In the example above, it would pick `M5` because it has the same tree as `A6`,
which is a commit that exists on `featureB`, but not on `master`.


Contact
--------

Please reports bugs and missing features at the [GitHub bug tracker]. This is
also where you can find the [source code].


`git-post-squash` was written by [Joachim Breitner] and is licensed under a
permissive MIT [license].

[GitHub bug tracker]: https://github.com/nomeata/git-post-squash/issues
[source code]: https://github.com/nomeata/git-post-squash
[Joachim Breitner]: http://www.joachim-breitner.de/
[license]: https://github.com/nomeata/git-post-squash/blob/LICENSE
