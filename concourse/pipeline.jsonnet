local c = import 'concourse/pipeline.libsonnet';

local pipeline = c.newPipeline(
  name = 'conrad',
  source_repo = 'getoutreach/conrad'
) {
   resources_: [
     $.dockerImage($.name),
   ],
  jobs_: [
    // Master Jobs
    $.newJob('Run Tests', 'Master') {
      plan_: $.steps([
        $.newTask(
          name = 'Test Conrad gem',
          path = 'concourse/tasks/test.yaml',
          semver = {},
          params = {},
        ),
      ]),
      on_success_: $.do([
        $.updateGithub('Test Conrad', 'success'),
        $.slackMessage(
          type = 'success',
          title = ':successkid: Master Branch Passed Tests Successfully!',
          text = 'All the tests ran successfully!',
        ),
      ]),
      on_failure_: $.do([
        $.updateGithub('Test Conrad', 'failure'),
        $.slackMessage(
          type = 'failure',
          title = ":fire: Master Branch Tests Failed :'(",
          text = 'There was a problem running the tests for the master branch.',
        ),
      ]),
    },
    // Pull Request Jobs
    $.newJob('Run PR Tests', 'Pull Request') {
      plan_: $.steps([
        $.newTask(
          name = 'Test Conrad gem',
          path = 'concourse/tasks/test.yaml',
          pr = true,
          semver = {},
          params = {},
        ),
      ]),
      on_success_: $.do([
        $.updateGithub('Test Conrad gem', 'success', pr = true),
        $.slackMessage(
          type = 'success',
          title = ':successkid: PR Passed Tests Successfully!',
          text = 'All the tests ran successfully!',
          inputs = [
            $.slackInput('source_pr'),
            $.slackInput(
              title = 'Pull Request',
              text = '<$(cat source_pr/.git/url)|#$(cat source_pr/.git/id)>',
            ),
          ],
        ),
      ]),
      on_failure_: $.do([
        $.updateGithub('Test Conrad gem', 'failure', pr = true),
        $.slackMessage(
          type = 'failure',
          title = ":fire: PR Tests Failed :'(",
          text = 'There was a problem running the tests for this PR.',
          inputs = [
            $.slackInput('source_pr'),
            $.slackInput(
              title = 'Pull Request',
              text = '<$(cat source_pr/.git/url)|#$(cat source_pr/.git/id)>',
            ),
          ],
        ),
      ]),
    },
  ],
};

[pipeline]
