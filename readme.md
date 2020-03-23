# README

This repo contain the source of the "DTP authorization code Flow" specification in markdown.

## How to use it?

The repo contain the specification in markdown file, to generate the xml/html file use the toll [markdown2rfc](https://github.com/oauthstuff/markdown2rfc) as follow:

```
docker run -v "`pwd`:/data" danielfett/markdown2rfc dtp-authorization-code-flow.md
```

This command should be executed in the root folder of this repo, the instruction `-v "``pwd``:/data"` will get the current path and mount as volume in a data folder in the image.

