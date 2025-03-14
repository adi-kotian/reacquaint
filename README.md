Reacquaint
<br>Make better bids, win better work

What is Reacquaint?
<br> Reacquaint is construction tender evaluation platform enabling bidders to upload tenders(PDF documents) and receive AI-driven assessments.


<img width="1512" alt="Screenshot 2025-03-10 at 11 21 57 AM" src="https://github.com/user-attachments/assets/1f32117a-bb1e-4e1d-8ca2-f703242e33bb" />
<br>
<img width="1512" alt="Screenshot 2025-03-14 at 2 53 36 PM" src="https://github.com/user-attachments/assets/680fe103-a6dd-4756-be31-eb647907e69c" />
<br>
<img width="1512" alt="Screenshot 2025-03-14 at 2 55 30 PM" src="https://github.com/user-attachments/assets/df2962fc-671a-4a15-a624-3acb555cde86" />

## Getting Started
### Setup

Install gems
```
bundle install
```

### ENV Variables
Create `.env` file
```
touch .env
```
Inside `.env`, set these variables. For any APIs, see group Slack channel.
```
CLOUDINARY_URL=your_own_cloudinary_url_key
```

### DB Setup
```
rails db:create
rails db:migrate
rails db:seed
```

### Run a server
```
rails s
```

## Built With
- [Rails 7](https://guides.rubyonrails.org/) - Backend / Front-end
- [Stimulus JS](https://stimulus.hotwired.dev/) - Front-end JS
- [Heroku](https://heroku.com/) - Deployment
- [PostgreSQL](https://www.postgresql.org/) - Database
- [Bootstrap](https://getbootstrap.com/) — Styling
- [Figma](https://www.figma.com) — Prototyping

## Acknowledgements


## Team Members
- Jason R. Rocha(https://www.linkedin.com/in/jason-rocha-37188a150/)
- Aditya Karkera
- Rafaela Yazawa
- Christopher Diaz

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
