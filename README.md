okay quick guide for GitHub+matlab:
best and easiest way is to have a branch for each question (might seem a lot but it's easier so as to not mess up what the other people are doing). 

so every time you begin any question first:
- git checkout main
- git pull origin main

  
then if main is updated (you can always check with git status) you can create your branch:
- git checkout -b name-of-the-branch (e.g. question-1-1, or task-1-1, we can decide how we want to name them)

  
then we fix the code (tutorial says only to modify the code between ???...???) and then if this is the first time pushing to this new branch you created you do:
- git add .
- git commit -m "T.1.1: blabla"
- git push -u origin name-of-the-branch

  
if this is not your first time, you can ignore everything after push in the last command, this is to set it up at the beginning

once you finished the task i put a sort of shield to main so that we dont accidentally push changes there and delete something from someone else, so you have to create a pull request. 
for this you have to go to github, open the Pull Request menu (there is a button) and click on "create a new Pull Request/PR". 
you select your branch and it asks you to select target branch and you have to select main (!!!! important). 
then you have to add a reviewer you can add me and i merge it and should be done (:
