
MORE IMPORTANT

- check appropriate expiration of email link

- check that drag-and-drop works for file area with multiple upload

* confirm proper Paypal micropayments as 2FA for instructors and/or special sites (e.g., book.ivo-welch.info/instructor)


MEDIUM IMPORTANT

* add more automatic tests, esp with respect to web controller

  - currently in progress

* autoforwarding of errors in quizzes to course instructor and/or site administrator


LESS IMPORTANT

* users can limit authentication to specific method only (e.g., via email only, via google only, via facebook only, via local only)

* maybe prevent original instructor from being removed by TA

* audit again: grep all Model/Model.pm functions for sudo double-security safety

* add permanent instructor testsite? (i.e., instructor read-only  readonly.testsite.syllabus.space)

* could enhance honeypot with dozens of hidden fields and one real one, which is indicated by a token

* maybe bulk registration of students, with limits to authentication to local method



VERSION 4

* make market for instructors and students: 1c/quiz?



----------------------------------------------------------------

BACKEND.

* maybe allow autonumbering of questions.

* maybe write check (error) and "lint" (warnings), following all equiz authoring guidelines.

