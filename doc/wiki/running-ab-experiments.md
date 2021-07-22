# Running AB Experiments

## Experiment setup:
- experiments can be set up by adding a data migration to `db/data`
- an example of how to set up an experiment can be found in `lib/seed/experiment_seeder.rb`

## Active patient experiment:
- experiment will be started by running a script either manually or by scheduling it
- the job can be run like so: `ExperimentControlServerice.start_current_patient_experiment(name, days_til_start, days_til_end, percentage_of_patients = 100)`
- the `percentage_of_patients` argument is optional and defaults to 100
- be sure that `days_til_start` leaves enough time to send any reminders that need to be sent before the appointment. For example, if the experiment has a treatment that involves sending reminders three days before the experiment begins, set `days_til_start` to at least four.
- the job will select patients and assign all eligible patients to treatment groups at random
- it will create all notifications for experiment patients, based on the date of their next appointment and the information in their treatment group's reminder templates. These will be marked as "pending" and will not be sent at this time.
- Then the messages will then be scheduled for delivery

## Stale patient experiment:
- stale patient selection is run via the command: `ExperimentControlService.schedule_daily_stale_patient_notifications(name, patients_per_day: PATIENTS_PER_DAY)`
- the `patients_per_day` argument is optional and defaults to 10,000
- this job should be scheduled because patient selection must occur every day of the experiment to ensure that patients do not become ineligible (by returning to care) between selection and the time their reminder is sent
- this job selects the specified number of patients per day to add to the experiment, assigns them to treatment groups, and creates notifications appropriate for their group. These notifications will be marked as "pending" and will not be sent at this time.
- patients in the control group will receive no reminders while other groups may receive multiple reminders over a period of days
- Then the messages will need to be scheduled for delivery.

## Notification scheduling
- notifications are scheduled to be sent daily via a job that will need to be run every day during the experiment before the notification window
  - the job can be run via the command: `AppointmentNotification::ScheduleExperimentReminders.perform`
  - because this job must be run daily, it should be scheduled via `config/schedule.rb`
- it will search for any pending notifications with a `remind_on` of today, mark the notification as "scheduled", and schedule a sidekiq worker to send the notification during the notification window
- in India, text messages will first be sent as WhatsApp messages. If the WhatsApp message fails, we will resend the message as SMS.
- in Bangladesh, text messages will first be sent as Imo messages. If the Imo message fails, we will resend the message as SMS.

## Experiment cleanup:
- after an experiment is over, its state should be changed to "complete"
  - stale patient experimeents are automatically changed to "complete" when the experiment end date has passed.
  - active patient experiments must be manually changed to "complete". Failure to change the experiment to complete will prevent us from starting another active patient experiment but has no other negative side effects.
- it's important to note that notifications can be scheduled beyond the experiment end date due to the cascading nature of notifications. The end date is used by the selection process and not to prevent notifications from being sent.
- to prevent notifications from being sent, the experiment must be marked "cancelled", not "complete". Experiments can be ended early via a [script](#ending-an-experiment-early).

## Ending an experiment early

If we need to end an experiment early, we can do it by running `ExperimentControlService.abort_experiment(experiment_name)`. This will change the experiment state to "cancelled" and marking all "pending" and "scheduled" notifications as "cancelled", which will prevent all unsent notifications from being sent.