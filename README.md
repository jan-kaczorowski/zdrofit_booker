# README

## Zdrofit booker

Zdrofit is a major gym network in Poland. It provides premium gym space and fitness classes with reputable trainers. However, attending the classes often requires booking, with the best trainers' classes being fully booked within 10-15 minutes from the time booking opens.

I wrote an app to automate the process to make sure the user gets booked just in time!


## Purpose

Auto-booking Zdrofit fitness classes without you having to watch them and manually subscribe to each and every one of them with your mobile app


## Scope

- Zdrofit API client (as a local gem, in lib folder)
- Scheduler on top of SQLite and SolidQueue
- simple TailwindCSS powered UI

## Caveats

Because I'm not using the most official API, but rather peripheral one, mimicking user actions, I have no ability to use the most apporpriate course of interaction - OAUTH. Instead, I'm relying on saving username and password in the DB (encrypted, but still), for the purpose of jobs being able to use them later, when an app has to book some Zdrofit class.

If you have trust issues - understandable - i suggest you just pull this project, and host anywhere. The slimmest VPS you can find will likely get the job done.