#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <errno.h>
#include <dlfcn.h>
extern int renameatx_np(int,const char*,int,const char*,unsigned int);
static void canary(int parent,const char* name) {
 int fd=openat(parent,name,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW,0600);
 if(fd>=0){const char*s="SYNTHETIC_RESET_RACE_CANARY";write(fd,s,strlen(s));close(fd);}
}
static int reset_rename(int from,const char* original,int parent,const char* stage,unsigned int flags) {
 const char*mode=getenv("HOMEVIEW_RESET_RACE");
 if(mode && (flags&RENAME_SWAP) && strcmp(mode,"swap-fail")==0){write(2,"RESET_GATE_FAULT:swap-fail\n",27);errno=EIO;return -1;}
 int result=renameatx_np(from,original,parent,stage,flags);
 if(result==0 && mode && (flags&RENAME_SWAP)) {
  if(strcmp(mode,"replace-retired")==0) {
   char retired[1024];snprintf(retired,sizeof(retired),"%s-captured-original",original);
   if(strncmp(original,"test-",5)==0 && renameat(parent,stage,parent,retired)==0 && mkdirat(parent,stage,0700)==0) {
    int replacement=openat(parent,stage,O_RDONLY|O_DIRECTORY|O_NOFOLLOW);
    if(replacement>=0){canary(replacement,"DO_NOT_DELETE");close(replacement);write(2,"RESET_GATE_RACE:replacement\n",28);}
   }
  } else if(strcmp(mode,"retarget-root")==0 && strncmp(original,"test-",5)==0) {
   char moved[1024];snprintf(moved,sizeof(moved),"%s.moved",original);
   if(renameat(parent,original,parent,moved)==0 && mkdirat(parent,original,0700)==0) {
    int replacement=openat(parent,original,O_RDONLY|O_DIRECTORY|O_NOFOLLOW);
    if(replacement>=0){canary(replacement,"DO_NOT_DELETE");close(replacement);write(2,"RESET_GATE_RACE:replacement\n",28);}
   }
  } else if(strcmp(mode,"retarget-parent")==0) {
   const char*path=getenv("HOMEVIEW_RESET_PARENT");
   if(path){char moved[4096];snprintf(moved,sizeof(moved),"%s.moved",path);
    if(rename(path,moved)==0 && mkdir(path,0700)==0) {
     int replacementParent=open(path,O_RDONLY|O_DIRECTORY|O_NOFOLLOW);
     if(replacementParent>=0 && mkdirat(replacementParent,original,0700)==0) {
      int replacement=openat(replacementParent,original,O_RDONLY|O_DIRECTORY|O_NOFOLLOW);
      if(replacement>=0){canary(replacement,"DO_NOT_DELETE");close(replacement);write(2,"RESET_GATE_RACE:replacement\n",28);}
     }
     if(replacementParent>=0)close(replacementParent);
    }
   }
  }
 }
 return result;
}
static int prepared_snapshot(int fd) {
 char path[4096];if(fcntl(fd,F_GETPATH,path)!=0)return 0;
 const char*name=strrchr(path,'/');return strstr(path,"/.homeview-reset-") && name && strcmp(name,"/mock-state.json")==0;
}
static ssize_t reset_write(int fd,const void*bytes,size_t count) {
 const char*mode=getenv("HOMEVIEW_RESET_RACE");
 if(mode && strcmp(mode,"write-fail")==0 && prepared_snapshot(fd)){write(2,"RESET_GATE_FAULT:write-fail\n",28);errno=ENOSPC;return -1;}
 return write(fd,bytes,count);
}
static int reset_sync(int fd) {
 const char*mode=getenv("HOMEVIEW_RESET_RACE");
 if(mode && strcmp(mode,"fsync-fail")==0 && prepared_snapshot(fd)){write(2,"RESET_GATE_FAULT:fsync-fail\n",28);errno=EIO;return -1;}
 return fsync(fd);
}
__attribute__((used)) static struct { const void*replacement;const void*original; }
reset_interpose[] __attribute__((section("__DATA,__interpose")))={
 {(const void*)reset_rename,(const void*)renameatx_np},
 {(const void*)reset_write,(const void*)write},
 {(const void*)reset_sync,(const void*)fsync}
};
