#!/usr/bin/env python3
# ============================================================
# APPLICATION FLASK VULNÉRABLE — LAB UNIQUEMENT
# Portail bancaire SecureBank avec injection SQL intentionnelle
# À déployer sur Ubuntu Server (192.168.100.20)
# ============================================================

from flask import Flask, request, session
import sqlite3

app = Flask(__name__)
app.secret_key = "supersecret123"  # Clé faible — volontairement vulnérable

DB_PATH = '/var/www/bank/db.sqlite'

@app.route('/')
def index():
    return '<h2>SecureBank Portal</h2><a href="/login">Login</a>'

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        user = request.form['username']
        pwd  = request.form['password']

        # VULNÉRABILITÉ INTENTIONNELLE : injection SQL
        conn = sqlite3.connect(DB_PATH)
        query = f"SELECT * FROM accounts WHERE customer_name='{user}' AND password_hash='{pwd}'"
        try:
            row = conn.execute(query).fetchone()
        except Exception as e:
            return f"DB Error: {e}", 500
        finally:
            conn.close()

        if row:
            session['user'] = user
            return f"<h3>Bienvenue {user} !</h3><p>Solde : ${row[3]}</p>"
        return "<p>Identifiants invalides.</p><a href='/login'>Retour</a>", 401

    return '''
    <h2>SecureBank — Connexion</h2>
    <form method="post">
        Utilisateur : <input name="username"><br><br>
        Mot de passe : <input name="password" type="password"><br><br>
        <input type="submit" value="Connexion">
    </form>
    '''

@app.route('/dashboard')
def dashboard():
    if 'user' not in session:
        return 'Non autorisé', 401
    conn = sqlite3.connect(DB_PATH)
    rows = conn.execute("SELECT customer_name, balance FROM accounts").fetchall()
    conn.close()
    table = "".join(f"<tr><td>{r[0]}</td><td>${r[1]}</td></tr>" for r in rows)
    return f"<h3>Dashboard Admin</h3><table border=1>{table}</table>"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
