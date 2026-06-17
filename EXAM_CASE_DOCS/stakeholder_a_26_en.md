# Stakeholder A — Performance Analytics Platform

## Competitiveness Analysis

## Context

You are developing an analytical data warehouse prototype for a performance analytics platform used by multiple Formula 1 teams.

Performance engineers use this system to evaluate how competitive their drivers were relative to the field in each race. Because circuits differ in length and characteristics, raw lap times cannot be compared directly across races.

Instead, performance must be evaluated relative to competitors within the same race.

This type of analysis helps teams:

- Assess whether performance upgrades reduced the gap to the winning pace.
- Identify circuits where the team consistently performs better or worse.
- Monitor whether competitiveness improves or declines across seasons.

The system must allow engineers to:

- Select a team.
- Select a driver.
- Filter by circuit.
- Filter by race conditions.
- Compare performance across seasons.

# User Story — Competitiveness Analysis

As a performance engineer, I want to understand how far each driver's race pace was from the race winner's race pace, and how that gap varies across circuits, seasons, and race conditions, so that I can evaluate realistic competitiveness and identify where and when the team performs best.

## Predefined Analytical Question

What is the difference between the average lap time of each driver and the average lap time of the race winner in the same race?

## Clarification

- Only drivers classified as `Finished` should be included.
- The race winner must be identified per race.
- For each race, calculate: average lap time of driver − average lap time of race winner.

This produces a comparable performance gap within each race.

# Your Analytical Question

You must define one additional analytical question derived from this user story.

Your question must incorporate at least one race condition variable as a dimension of analysis. Race conditions available in this dataset include:

- Wet vs dry races, derived from weather data.
- Temperature ranges, derived from weather data.
- Circuit.
- Season.

Your question must:

- Be neutral.
- Be directly answerable using the available data.
- Be operational, not vague.
- Lead to meaningful analytical modelling decisions.
