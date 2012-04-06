#!/usr/bin/perl

###################################################################################
###										###
###              WSBWL 1.0 (Web Search Based on Web Log)			###
###              http://www.github.com/PrashantBhutani/              		###
###										###
### This program is copyright (c) by						###
### 1) Dr. Bhaskar Biswas <bhaskar.cse@itbhu.ac.in>				###
### 2) Prashant Bhutani <prashantbhutani2008@gmail.com>				###
### 2011-2020 or stated otherwise.						###
###										###
### This program is free software. You can redistribute it and/or modify it     ###
### under the terms of version 2 of the GNU General Public License, which you   ###
### should have received with it.						###
###										###
### This program is distributed in the hope that it will be useful, but		###
### without any warranty, expressed or implied.					###
###################################################################################



# checks whether the number of arguments passed is 2 or not
if(@ARGV != 2)
{
   printf "\n\n\t Sorry the arguments are not valid, so we are halting the program\n";
   printf "\n The synopsis is perl WSWBL.pl <search query> <option>";
   printf "\n\n or if the file is made executable using chmod u+x WSWBL.pl, you can use ./WSWDL.pl <search query> <serach option>";
   printf "\n\n <options> ...";
   printf "\n -p  \t\t<personalized web search>\n\t\tThis will show only the web-pages you have hit/visited so far.";
   printf "\n -np  \t\t<diable personalized search>\n\t\tThis will diable personalized web-search and show all search results.";
   printf "\n -a  \t\t<personalized search but all results>\n\t\tThis will return all search results sorted on the basis of web-pages visited previously\n\n";
   die "\t\t\tHope this helps :)\n";
}

# assigning argument variables to the local variables
my ($search_query,$search_option) = @ARGV;


# $log_file is pointing to the web-log file
# containing the browsing history of the user 
my $log_file = "./log.txt";


# @hash_file contains the database built using log-files
my $hash_file = "./hash.txt";


# creating a hash variable to hash the keys
# and keeps the time they have been hit as the values
my %website_hash;


# a variable to seek through the hash table
my $website_logfile;


# check if the hash file exists
# if it does, then develop the hash from this file
# else parse the log file
if(-e $hash_file)
{
   # opening the hash file for reading the hash data
   # or the program will HALT if the file was not open
   open(HASH_FILE,"<$hash_file")||die "couldn't open hash file";
   

   # a for loop to create the hash using the data from the hash file
   for $each_line (<HASH_FILE>)
   {
      # remove the trailing newline character from each line
      chomp $each_line;
      
      # The data in hash file is saved as
      # <Website> (some space) <number of times it has been hit by the user>
      # this line reads the regualr expression and does the obvious
      ($website_logfile,$value) = $each_line =~ /([\S]*)\s*(\d)*/;
      $website_hash{$website_logfile} = $value;
    }

   close HASH_FILE;
}


# hash file was not present
# so use the log file to fetch the user's data

else
{
   # open log file for reading or HALT the program
   open(LOG_FILE,"< $log_file")||die "couldn't open log file";

   # parse the log file data
   for $each_line (<LOG_FILE>)
   {
      chomp $each_line;
      
      # the regular expression carve out the web-site names from the log file
      #($website_logfile) = $each_line =~ /.*(http.*www\..*\....\/[\S]*\/).*/;
      ($website_logfile) = $each_line =~ /.*(http[\S]*\/).*/;
     
      # check whether the entry to the web-site exists in the hash or not
      # if it does increase the hit value by 1
      # if it does not enter the web-site in hash
      if(exists $website_hash{$website_logfile})
      {
         $website_hash{$website_logfile}++;
      }

      else
      {
         $website_hash{$website_logfile}=1;
      }
    } 

   close LOG_FILE;

   # open hash file to write hash data to it which is utilized later
   open(HASH_FILE,">$hash_file")||die "couldn't open hash file";

   # print out the hash data in hash file
   while (($key,$value) = each %website_hash)
   {
      print HASH_FILE "$key   $value"."\n";
   }

   close HASH_FILE;
}


# This path points to the Yahoo::Search module used to search an expression
# in yahoo and gives the result back in pre-specifies format
use lib './Yahoo-Search-1.11.3/blib/lib';

# Includes the Yahoo::Search module
use Yahoo::Search;

# This function gives the parameters to the Results function to send the
# searched expression with conditions to the server and get it back
my @Results = Yahoo::Search->Results(Doc => $search_query,
                                      AppId => "YahooDemo",
                                      # The following args are optional.
                                      # (Values shown are package defaults).
                                      Mode         => 'all', # all words
                                      Start        => 0,
                                      Count        => 25,
                                      Type         => 'any', # all types
                                      AllowAdult   => 0, # no porn, please
                                      AllowSimilar => 0, # no dups, please
                                      Language     => undef,
                                     );

 warn $@ if $@; # report any errors


# If the option chooses by user is of Not Personlaized, then
# this block will be executed
if($search_option eq '-np')
{
    # calls sub-routine names print_all to print the search data
    &print_all;
}

# If the user chooses to personalize his search
# then this block will execute
elsif ($search_option eq '-p')
{
   # defining a local array variable
   my @personalized_array;

    # defining a loop to build an array which will contain the 
    # personalized web search data
    LABEL: for my $result (@Results)
    {
	# checks whether the Url we get from web-search has an
        # entry in user's web-log
        if(exists $website_hash{$result->Url})
	{   
            # if the Url has an entry, insert it in array
            # containing personalized search Urls
            for($i=0; $i<= $#personalized_array;$i++)
            {
               # checks how many times a web-page is visited and 
               # depending on the hit ratio sorts it
               if ($website_hash{$result->Url} > $website_hash{$personalized_array[i]})
               {
                     # entry is made in array based on hit ration of Url
                     splice (@personalized_array,$i,0,$result->Url);
                     # if the entry is made goto next element in original web-search array
                     next LABEL;
               }
            }   
            # if the Url has the least hit ratio, insert it in the end of the array
            push @personalized_array,($result->Url);
        }
     }

    # if the user is asking for personalized search but there is no previous
    # data entry for any of the Url in present search, then show the 
    # original web search results
    if($#personalized_array == -1)
    { 
        print "sorry no previous personal data, showing all results\n\n";
        &print_all;
    } 
   
    # there are data entries for some of the Urls in web-logs
    # so personalized web search is shown
    else
    {
       foreach (@personalized_array)
       {
	   print "Url: $_\n";
       }
    }
}

# if the user chooses to see all the results but in sorted order,
# then this block will get executed
elsif ($search_option eq '-a')
{
   # defining a local array variable
   my @personalized_array;

   # defining a loop to build an array which will contain the web search
   # data but in sorted order with respect to previous entries
   LABEL: for my $result (@Results)
   {
        # check if the Url has an entry in web-log
        if(exists $website_hash{$result->Url})
	{   
            # if the Url has an entry in web-log, enter the Url in
            # array in sorted order
            for($i=0; $i<= $#personalized_array;$i++)
            {
               # checks whether the entry in array is in web-log or not
               if(exists $website_hash{$personalized_array[i]})
               {
                   # if the entry is in web-log, enter the Url in sorted order
               	   if ($website_hash{$result->Url} > $website_hash{$personalized_array[i]})
                   {
                       splice (@personalized_array,$i,0,$result->Url);
                       next LABEL; # goto next url entry
                   }
               }
               # if the Url was not in web-log, enter the present Url (which was in web-log)
               # just before the undefined URL's place
               else
               {
                   splice (@personalized_array,$i,0,$result->Url);
                   next LABEL;
               }
            }   

            # enter the Url present in web-log in array
            # if the array was empty and it is first one to come
            push @personalized_array,($result->Url) if ($#personalized_array == -1);
        }
        # enter all other Urls (not present in web-log) in end of the array
        else
        {
           push @personalized_array,($result->Url); 
        }
    }

    # print out the results
    foreach (@personalized_array)
    {
       print "Url: $_\n";
    }
}

#sub-routine to print out the original web-search data
sub print_all
{
    for my $result (@Results)
    {
        printf "Url:%s\n",       $result->Url;
        #printf "Summary: %s\n",  $result->Summary;
    }
}
