#
# (c) 2011 Jan Gehring <jan.gehring@gmail.com>
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
#

package Net::SSH2::Expect;

use strict;
use warnings;

our $VERSION = "0.1";

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = {};

   bless($self, $proto);

   $self->{"__shell"} = $_[0]->channel();
   $self->{"__shell"}->pty("vt100");
   $self->{"__shell"}->shell;

   return $self;
}

sub shell {
   my ($self) = @_;
   return $self->{"__shell"};
}

sub spawn {
   my ($self, $command, @parameters) = @_;

   my $cmd = "$command " . join(" ", @parameters);
   $self->shell->write($cmd . "\n");
}

sub soft_close {
   my ($self) = @_;
   $self->hard_close;
}

sub hard_close {
   my ($self) = @_;
   die;
}

sub expect {
   my ($self, $timeout, @match_patterns) = @_;

   eval {
      local $SIG{'ALRM'} = sub { die; };
      alarm $timeout;

      my $line = "";
      while(1) {
         my $buf;
         $self->shell->read($buf, 1);
         if($self->_check_patterns($line, @match_patterns)) {
            $line = "";
            alarm $timeout;
            next;
         }
         $line .= $buf;
      }
   };
}

sub send {
   my ($self, $str) = @_;
   $self->shell->write($str);
}

sub _check_patterns {
   my ($self, $line, @match_patterns) = @_;

   my $pattern_hash = { @{$match_patterns[0]} };

   for my $pattern (keys %{ $pattern_hash }) {
      if($line =~ $pattern) {
         my $code = $pattern_hash->{$pattern};
         &$code($self, $line);
         return 1;
      }
   }
}

1;

