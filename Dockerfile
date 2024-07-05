FROM ubi9/ubi 

ADD helpers/ /usr/local/bin

USER 1001
CMD echo "OKD Utilites 0.1.1" 
