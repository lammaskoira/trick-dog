# lammaskoira/trick-dog

A trick dog will do the tricks it is told to do on a given set of obstacles/devices/circumstances.

This tool will do specific tricks on given GitHub repository... and by tricks
I mean, it will run bash scripts.

The intent is to automate whatever needs to be done on a given repository. e.g.
generating Pull Requests at scale!

## Running

A sample run looks as follows:
```bash
go run main.go -o <GitHub org> [-r <GitHub repo>] -p <processor or trick>
```

Note that credentials to the GitHub API are required. The `GITHUB_TOKEN`
environment variable is accepted. The credentials set by the
[GitHub CLI](https://cli.github.com/) are also accepted, so, by using
that you can run the program without having to set the credentials.

### Samples

* To run the script `./samples/label.sh` on the repository `lammaskoira/trick-dog`:

```bash
go run main.go -o lammaskoira -r trick-dog -p ./samples/label.sh
```

* To run the script `./samples/label.sh` on the `lammaskoira` organization:

```bash
go run main.go -o lammaskoira -p ./samples/label.sh
```

## How?

This clones each repo in a temporary directory and runs the processor on it.

## Why?

Because I can... there's no reason to not do it.