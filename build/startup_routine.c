#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>


const char* update_current_user =
"/etc/samba/custom/update_current_user.sh";

const char* update_samba_users =
"/etc/samba/custom/update_samba_users.sh";

const char* update_samba_dirs =
"/etc/samba/custom/update_samba_dirs.sh";

const char* bash = "/bin/bash ";

int main(int argc, char* argv[])
{
    setuid(0);   // you can set it at run time also
    // Update current user (non root user)
    if (argc > 2)
    {
        int size = 1 + strlen(bash) + strlen(update_current_user) + 2 + strlen(argv[1]) + strlen(argv[2]);
        char* cmd = malloc(size);
        memset(cmd, 0, size);
        //Concatinate string
        strcat(cmd, bash);
        strcat(cmd, update_current_user);
        strcat(cmd, " ");
        strcat(cmd, argv[1]);
        strcat(cmd, " ");
        strcat(cmd, argv[2]);
        //Run
        system(cmd);
        free(cmd);
    }

    //Update samba users
    {
        int size = 1 + strlen(bash) + strlen(update_samba_users);
        char* cmd = malloc(size);
        memset(cmd, 0, size);
        //Concatinate string
        strcat(cmd, bash);
        strcat(cmd, update_samba_users);
        //Run
        system(cmd);
        free(cmd);
    }

    //Update samba workdirs
    {
        int size = 1 + strlen(bash) + strlen(update_samba_dirs);
        char* cmd = malloc(size);
        memset(cmd, 0, size);
        //Concatinate string
        strcat(cmd, bash);
        strcat(cmd, update_samba_dirs);
        //Run
        system(cmd);
        free(cmd);
    }
    return 0;
}