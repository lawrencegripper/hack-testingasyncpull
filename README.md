# Testing async pre-pull 

This is a set of results and tests that I've put together to prove if doing an async pull of the pods main containers while an init container is running will speed up pod start times for those using init containers. 

## How to use?

- ./runner.sh: spins up two clusters and deploys the yaml from ./single-init into the normal cluster and the async cluster which is running the adapted behavior
- ./cal.py: takes the output from `runner` and calculates results into a `results.txt` under each results folder to compare normal vs aysnc
- ./gen.sh: is used to gen container images of specific sizes

## First results

In [results-05288](./results-05288) you can see the timings from a run using commit: https://github.com/lawrencegripper/kubernetes/commit/052887b5dc91053398ba4e8c0034b229674c1a34 

Suprisingly what this test showed was that the async pulls didn't have any impact on startup times unless the main pod image was around 1000mb (even [then not consistently](results-05288/gcrresults/results-1000mb-10sec/results.txt)). This was suprising. 

Digging into the results what you could see was that the `busybox` image used by the init container tool significantly longer to pull when using the `async` code than the normal `1.17` code. 

Looking again it appears that the `parrellelPull` is queuing up the async items (everything but the init container) then only starting pulling the init container when another image pull has finished. 

To resolve this I've put together [commit 47114](https://github.com/lawrencegripper/kubernetes/commit/471141b2e1e70a7e0c99ef14c4ea92b4797eb9e7) which ensures the first image in the queue for the `puller` is the `initContainer` which will be run first. 

This should ensure the async pulls are performed in the most efficient order. 

## Results with ordered async 

In [results-47114](./results-47114) testing [commit 47114](https://github.com/lawrencegripper/kubernetes/commit/471141b2e1e70a7e0c99ef14c4ea92b4797eb9e7) we see an ~10 second improvement on startup time in all the tests and minimal no impact on the control group (one slower by 1 sec one faster by 5 secs - will run more iterations). 

This change ensures that async pulls are started for all the containers used by the pod BUT now they are started inorder of their use so init1 is pulled first, init2 then main pod containers. This proves the issues seen with commit 05288 are due to the init container being last in the queue so starting the init container is held up by the other async pulls. 

Example 200mb container with 10sec init:
```
time: 31 file: ./results-200mb-10sec/**normal**-200mb-10sec.json runat:2020-02-25 11:49:14.440568
time: 13 file: ./results-200mb-10sec/**async**-200mb-10sec.json runat:2020-02-25 11:49:14.456872
time: 29 file: ./results-200mb-10sec/**normal**-200mb-10sec.json runat:2020-02-25 11:52:58.657274
time: 13 file: ./results-200mb-10sec/**async**-200mb-10sec.json runat:2020-02-25 11:52:58.672962
```