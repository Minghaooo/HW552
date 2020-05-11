//
// Created by liuyin14 on 2020/4/3.
//


#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


pthread_t a, b;
pthread_mutex_t count_lock;
pthread_cond_t count_nonzero;
int count = 0;

void* decrement_count()
{
    pthread_mutex_lock(&count_lock);
    printf("Decrement begin, count = %d\n", count);
    while (count == 0)
        pthread_cond_wait(&count_nonzero, &count_lock);
    count = count - 1;
    printf("Decrement finish, count = %d\n", count);
    pthread_mutex_unlock(&count_lock);
    return NULL;
}

void* increment_count()
{
    pthread_mutex_lock(&count_lock);
    printf("Increment begin, count = %d\n", count);
    if (count == 0)
        pthread_cond_signal(&count_nonzero);
    count = count + 1;
    printf("Incremented, count = %d\n", count);
    pthread_mutex_unlock(&count_lock);
    return NULL;
}

int main(){

    if (pthread_mutex_init(&count_lock, NULL) != 0) {
        printf("\n mutex init has failed\n");
        return 1;
    }

    if (pthread_cond_init(&count_nonzero, NULL) != 0) {
        printf("\n cond init has failed\n");
        return 1;
    }

    pthread_create(&a, NULL, &decrement_count, NULL);
    pthread_create(&b, NULL, &increment_count, NULL);
//    pthread_create(&a, NULL, &decrement_count, NULL);

    pthread_join(a, NULL);
    pthread_join(b, NULL);

    pthread_mutex_destroy(&count_lock);


    return 0;


}