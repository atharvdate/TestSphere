# TestSphere — AI-Powered Recruitment Portal

[![Java](https://img.shields.io/badge/Java-17+-orange?style=for-the-badge&logo=java)](https://www.java.com)
[![MySQL](https://img.shields.io/badge/MySQL-Database-blue?style=for-the-badge&logo=mysql)](https://www.mysql.com)
[![Apache Tomcat](https://img.shields.io/badge/Tomcat-Server-yellow?style=for-the-badge&logo=apachetomcat)](https://tomcat.apache.org)
[![REST API](https://img.shields.io/badge/API-RESTful-green?style=for-the-badge)]()
[![AI Integration](https://img.shields.io/badge/AI-Resume%20Scoring-purple?style=for-the-badge)]()

A cloud-ready recruitment platform that automates candidate evaluation using AI-powered resume scoring, built with Java Servlets, MySQL, and RESTful API integration.

---

## Overview

TestSphere is a full-stack recruitment system designed to streamline campus hiring workflows. It enables recruiters to manage hiring drives, evaluate candidates, and automate resume screening using AI.

The platform reduces manual effort by integrating an AI scoring system that analyzes resumes and provides a score along with reasoning.

---

## Recruitment Process Flow

1. AI Resume Screening  
   - Score (0–100)  
   - Reasoning

2. Aptitude Round  
   - MCQ-based online assessment  
   - Time-bound test window  
   - Auto-evaluation   

3. GD Round  
   - Manual 

4. Technical Round 
   - Manual

5. HR Round
   - Manual

(*Manual rounds are scalable for automation)

---

## Key Features

- Student Registration & Drive Application  
- Recruiter Panel for Drive Management  
- College/Admin Approval System  
- Resume Upload & Storage  
- AI-Based Resume Scoring (ATS-style evaluation)  
- Asynchronous Processing for AI scoring  
- Shortlisting based on AI score  
- Authentication & Role-Based Access (Student / Recruiter / Admin)  
- Resume Serving & Download  

---

## AI Resume Scoring

The system integrates with an external AI API (via OpenRouter) to evaluate resumes.

Flow:

Resume PDF → Text Extraction → AI API → Score + Reason → Database

- Generates a score (0–100)  
- Provides reasoning for evaluation  
- Runs asynchronously to avoid blocking user requests  

---

## System Architecture

Frontend (JSP)
→
Servlet Controllers
→
Utility Layer
→
Database (MySQL)
→
External AI API (OpenRouter)

---

## Tech Stack

| Technology | Usage |
|------------|------|
| Java (Servlets, JSP) | Backend logic |
| MySQL | Database |
| JDBC | DB connectivity |
| Apache Tomcat | Server |
| Maven | Build tool |
| OpenRouter API | AI resume scoring |
| PDFBox | Resume text extraction |
| Git + GitHub | Version control |

---

## Setup & Run

1. Clone repository

git clone https://github.com/atharvdate/TestSphere.git
cd TestSphere

2. Configure Database

   Run SETUP_DATABASE.sql

3. Add API Key

   Set OPENROUTER_API_KEY

4. Run on Tomcat

http://localhost:8080/testsphere

---

## Deployment

Designed for Oracle Cloud Always Free Tier (VM + Tomcat + MySQL)

---

## Developer

Atharv Avirat Date  
LinkedIn: https://www.linkedin.com/in/atharv-date-a763b724a  
Email: atharvdate5114@gmail.com
