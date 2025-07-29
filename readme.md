# Data Version Control

To manage the pipeline data we use [DVC](https://dvc.org/) to essentially have version controlled archive for our data. It is linked to git, so the data and code versions are 'synced'.

See the [DVC docs](https://dvc.org/doc) for more information, but in short:

- the actual data that is managed using DVC is stored in folder (`my_example_data`) that is ignored by git (we don't want the actual data in the git repository)

- for every file/folder that is managed using DVC a `.dvc` file is added to the repository, which contains some metadata that is used by DVC tools to know how to find the most up-to-date version of the corresponding file/folder.

- The actual data is stored on Azure in a Blob Storage (see [.dvc/config](../.dvc/config))

## Setup DVC

### Prerequisites

First make sure DVC is installed on your system

- mac: `brew install dvc`

After installing DVC onto your device, to make sure that merge conflicts are automatically solved if more than one branch updates the data sources, add the following settings for git config in bash (these settings tell git to treat .dvc files differently and allows dvc to solve file conflicts):

```bash
git config merge.dvc.name 'DVC merge driver'
git config merge.dvc.driver 'dvc git-hook merge-driver --ancestor %O --our %A --their %B'
```

### Prepare Data

Latest resources should be pulled from Azure using the following command (Only add new files after running the command):

```bash
dvc pull
```
df
### Configure the DVC remote (required once for the repository)

_Note that configuration was performed when DVC was initially configured and does NOT need to be repeated by every developer_

Add the Azure remote for DVC

    dvc remote add -d azureapp azure://dvc-data-storage/my_example_data

Configure the Azure storage account name:

    dvc remote modify azureapp account_name 'timelinedevapp'

The above configurations are stored in the file [.dvc/config](../.dvc/config), which will be commited to the repository (and is therefore shared by all developers).

OPTIONAL if the connection doesn't work:

Install the Azure CLI (if not already installed):

    brew install azure-cli

Log into your Azure account using the CLI:

    az login

### Configure sas token (required one-time setup for each development environment)

_Note: This step may not be necessary if you're already authenticated or using a service principal._

Add the sas token for Azure authentication (The sas token can be found in 1Password on the item `Boeing EEC Mark (Azure/Gitlab)`).

Use the following command to configure DVC to use the sas-token:

    dvc remote modify --local azureapp sas_token "<sas-token>"

IMPORTANT - Make sure to add the `--local` flag so the secret sas-token is stored in `.dvc/config.local` which is ignored by git. Without the `--local` flag the sas-token would be written to `.dvc/config` and it could end up in the git history.

## Working with DVC on the project

Generally you'll be using DVC to do two things:

1. Fetch data - to have the most up-to-date data locally

2. Push data - to "publish" data changes so they can used by other developers

### Fetch data using DVC

At any moment the `.dvc` files on your current branch will contain information on what the latest data for that branch is. Using the following command DVC will fetch any missing data from the remote and place the appropriate data in the managed folder(s):

    dvc pull

Note that the `pull` command basically performs both a `dvc fetch` to pull data from the remote into the local DVC cache and a `dvc checkout` to update the files in the folders manager by DVC (see [docs](https://dvc.org/doc/command-reference/pull#description)). So if you know you already have all the data in your local cache, just doing a `dvc checkout` can be faster.

### Push new/updated data

If you're making changes to the data (either because you're adding changes to the pipeline that require new data, or you're adding a new version of an existing data file, or you're reorganising/moving files within the data folder), follow ALL of the these steps:

1. First, BEFORE MAKING THE CHANGES to the data folder(s)/file(s), make sure your local data is up-to-date and run `dvc pull` [see Fetch data using DVC](#fetch-data-using-dvc)

    - Note that this is important because if your data wasn't up-to-date before you made the changes, then you'll be pushing additional, unintended changes along with the changes you made intentionally (effectively "undoing" the updates you didn't apply yet).

    - Note also that `dvc pull` will remove/undo any changes you made locally to the data folders, so make sure to `pull` first.

2. Make the changes you need to the data (add/move/remove the files, also make sure to remove the existing version if you're updating an existing file).

    - Perform a sanity check by running `dvc diff` and checking if DVC reports the expected changes.

2. Run `./scripts/dvc-push` to upload the changes to the remote (this way they become available for other developers).

    - Note that after pushing, DVC will update the local .dvc file(s) for the files/folders that contained changes.

3. Commit the updated `.dvc` files to git

    PLEASE make sure follow the following guidelines when committing data changes (see [Resolving Conflicts](#resolving-conflicts) below for why this is important):

    - Avoid combining data updates with other changes in a single commit; dedicated commits for data updates will make it easier to find what you need if you're later searching through the history of data changes.

    - Add a descriptive but short message to the first line of the git message (ideally mentioning which files/folders were updated).

    - Add the full diff that is printed after running `./scripts/dvc-push` to the body of the git commit message (below the first line). This way it is easier to see from the git history when certain files were added/updated.

### Resolving Conflicts

We're probably gonna have conflicts very often because every branch with data updates will update the same `.dvc` file, so if multiple branches contain data updates, they will always have a git conflict on the `.dvc` file(s).

There are various ways to solve conflicts, see also the [DVC docs](https://dvc.org/doc/user-guide/how-to/resolve-merge-conflicts#how-to-resolve-merge-conflicts-in-dvc-metafiles).

The `git merge driver` mentioned in the docs is a useful tool to automatically solve merge conflicts. Instead of pikcing one of the hashes from the `.dvc` file,
you can update the git config settings to allow DVC to solve the merge itself. It checks which files have been added, removed or modified by both branches
and automatically updates your hash to include both changes. In case it can not resolve all conflicts there is always the possibility to manually resolve the conflicts.