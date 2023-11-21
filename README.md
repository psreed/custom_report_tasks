# custom_report_tasks

A set of Puppet Tasks for custom Puppet Enterprise reports using the PuppetDB APIs

## custom_report_tasks::unresponsive_nodes

This Puppet Task supports the Puppet Enterprise Orchestrator (when installed as a Puppet module in the environment) or can be run from the command line utility Puppet Bolt.

To schedule a periodic run of this task with Puppet Enterprise, the Puppet Orchestrator Scheduled Tasks feature can be used.
To schedule a periodic run of thie task with Puppet Bolt, a "cron" job (Linux) or task within the "Task Scheduler" (Windows) can be used.

### Usage: 

#### To generate a report using Puppet Bolt, run the following command:

`bolt task run custom_report_tasks::unresponsive_nodes -t <target_host>`

Note: The target host can be any host that has a puppet agent installed. A Puppet Enterprise access token will need to be made available to the task. 
If the token is not provided as a parameter, the task will attempt to use the content of an existing token file located at `/root/.puppetlabs/token`.
See the task parameters to see how to define a custom token file location or provide the token directly.

#### To list additional supported task parameters, run the following command:

`bolt task show custom_report_tasks::unresponsive_nodes`



