# pad-dspace-infra: CDL DSpace Devops tools: Documenation

## The build.sh script
```bash
./build.sh --help
Usage: ./build.sh [-h] [--skip IMAGES]
Build and push DSpace Docker images to AWS ECR

Options:
  -h, --help           Show this help message and exit
  --skip IMAGES        Comma-delimited list of images to skip, valid values are 'backend', 'frontend', 'other'
  --no-trivy           Don't use Trivy to scan images for vulnerabilities before pushing them (trivy on by default)
  --verbose            Print verbose Trivy scan results (default: false)
  --debug              Print debug information (off by default)
```
### How to push an ad-hoc image to our ECR

```bash
OTHER_IMAGES="dspace/dspace:dspace-7_x" ./build.sh --skip "backend,frontend" --no-trivy
```
breaking that down:
- we can push any image into our ECR by just passing the image URL and tag into the build.sh script using the OTHER_IMAGES environment variable.
- turn off the builds of the frontend and backend images, they take a really long time
- `--no-trivy` just makes it faster.


## Diving Deeper

* [Getting Started with
  Sceptre](https://docs.sceptre-project.org/latest/docs/get_started.html)
* [Sceptre
  Terminology](https://docs.sceptre-project.org/latest/docs/terminology.html)
* [Sceptre CLI](https://docs.sceptre-project.org/latest/docs/cli.html)
* [DSpace 7.x
  Documentation](https://wiki.lyrasis.org/display/DSDOC7x/DSpace+7.x+Documentation)
* [DSpace and Docker](https://wiki.lyrasis.org/display/DSPACE/DSpace+and+Docker)
* [Solr Reference Guide](https://solr.apache.org/guide/solr/latest/index.html)
