# Simple License Management System

This Ruby on Rails application implements a simple License Management System that enables administrators to manage accounts, users, products, subscriptions, and license assignments. It supports assigning and unassigning licenses to multiple users and products in a single operation, with clear validation and feedback.

## Objective

Build a system to assign licenses to users on an account based on active subscriptions to products, track available/used licenses, and prevent invalid assignments.

## Tech Stack

- Ruby `3.3.4`
- Rails `7.1`
- PostgreSQL
- RSpec, FactoryBot
- Turbo/Importmap (no Node/Yarn required)

## Core User Stories & Acceptance Criteria

### 1) Adding an Account
- Create an account with a name; redirect to account details page.

### 2) Adding a Product
- Create a product with name and description; redirect to product details page.

### 3) Adding a User to an Account
- Create user with name, email, and `account_id` (required).
- Email uniqueness validated (case-insensitive); redirect to the account’s users list.

### 4) Adding a Subscription for an Account/Product
- Create subscription with `account_id`, `product_id`, `number_of_licenses` (> 0), `issued_at` (now), `expires_at` (after issued_at).
- On success, redirect to the account’s subscriptions list.
- Deletion is restricted if license assignments exist for the same account/product.

### 5) Assigning/Unassigning Licenses
- On an account page, select multiple products and multiple users; click Assign or Unassign.
- System validates capacity per product and prevents partial assignment when over capacity.
- If a user already has a license for a product, duplicates are skipped and reported.
- A separate page shows all assigned licenses for the account, grouped by product.

## Getting Started

1) Prerequisites
- Ruby 3.3.4, PostgreSQL, Bundler

2) Setup
```bash
bundle install
bin/rails db:setup
bin/rails server
```
Visit `http://localhost:3000`.

3) Running Tests
```bash
bundle exec rspec
```
