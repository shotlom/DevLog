package DevLog;
use Moose;
#use Moose::Util::TypeConstraints;
use DBI;
use JSON;
use DateTime;
use FindBin qw($Bin);
use Env;


=head1 DevLog

Custom logger module for development purposes

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Use this module to log a transaction to a database location specified by logpath

Code snippet.

  use DevLog;
  
  my $log = DevLog->new( 
    logpath => $log_path, #required, defaults to current directory of script \\db
    logdb   => $log_db, #required, defaults to 'Log.db'
    date    => $current_date, #defaults to current date
    time    => $current_time, #defaults to current time
    comment => $comment,
    status  => $status,
    keyword => $keyword, #required
    errmsg  => $errmsg, #required
    script  => $script_name,
    user    => $user_name # defaults to $ENV{'USERNAME'}
  );

  $log->log;
     
=cut
 
 my $defaultdb_dir = $Bin.'\\db\\';
 my $defaultdb = $defaultdb_dir.'\\Log.db';
 
 has 'keyword' => ( is => 'rw', isa => 'Str', required => 1); 
 has 'logpath' => ( is => 'rw', isa => 'Str', required => 1, default => $defaultdb_dir);
 has 'logdb' => ( is => 'rw', isa => 'Str', required => 1, default => 'Log.db');  
 has 'status'  => ( is => 'rw', isa => 'Str'); 
 has 'date'  => ( is => 'rw', isa => 'Num', required => 1, default => sub { sprintf("%4s%02s%02s", ((localtime)[5] + 1900 ), (localtime)[4]+1 , (localtime)[3] )} ); 
 has 'time'  => ( is => 'rw', isa => 'Num', required => 1, default => sub { sprintf("%02s%02s%02s",(localtime)[2] , (localtime)[1] , (localtime)[0] )}); 
 has 'errmsg' => ( is => 'rw', isa => 'Str', required => 1); 
 has 'script' => ( is => 'rw', isa => 'Str'); 
 has 'comment' => ( is => 'rw', isa => 'Str'); 
 has 'user' => ( is => 'rw', isa => 'Str', default => $ENV{'USERNAME'} ); 
 
=head2 EXPORTS

* dev_log()
* list()

=head2 SUBROUTINES/METHODS

=head2 dev_log()
  
Creates a logging database for tracking development of scripts

=cut

sub dev_log{
  my $self = shift;
  if ( $defaultdb_dir ne $self->logpath ) {
    if ( ! -d $self->logpath ){ 
      mkdir ($self->logpath); 
      print  "Created new development db directory [$self->logpath]\n"; 
    } ;
  }
  else{  
    mkdir ($defaultdb_dir) if ( ! -d $defaultdb_dir );
  }  
  my $db = $self->logpath.$self->logdb;
  my $dbh = DBI->connect(          
      "dbi:SQLite:dbname=$db", 
      "",                          
      "",                          
      { RaiseError => 1, AutoCommit => 0},         
  ) or die print $DBI::errstr;
  
  my $primary_key = 'PRIMARY KEY (Script, Date, Time)';
  $dbh->do("CREATE TABLE IF NOT EXISTS LOG(
    Script    TEXT,
    Keyword   TEXT, 
    Status    TEXT, 
    Comment   TEXT, 
    Errmsg    TEXT,
    Date      TEXT, 
    Time      TEXT, 
    User      TEXT,
    $primary_key
  )");
    
  my $sth = $dbh->prepare("INSERT INTO LOG VALUES ( ?, ?, ?, ?, ?, ?, ?, ? )");
  my @values = ($self->script, $self->keyword, $self->status, $self->comment, $self->errmsg, $self->date, $self->time, $self->user );
  $sth->execute(@values) or die return $sth->errstr;
  $dbh->commit;  
  $dbh->disconnect();
  return 1;    
}

=head2 list

Return an array of all logs within the Sqlite database
  
=cut

sub list{
  my $self = shift;
  my $db = $self->logpath.$self->logdb;
  my $dbh = DBI->connect(          
      "dbi:SQLite:dbname=$db", 
      "",                          
      "",                          
      { RaiseError => 1, AutoCommit => 0},         
  ) or die print $DBI::errstr;
  my $sth = $dbh->prepare("SELECT * FROM LOG");
  $sth->execute;
  my $hash_ref = $sth->fetchall_hashref( [ qw(Script Date Time) ]);
  $dbh->disconnect();
  return $hash_ref;
}

=head1 AUTHOR

Sholto Maud, C<< <sholto.maud at gmail.com> >>

=head1 BUGS

Please report any bugs in the issues wiki.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Logger


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Sholto Maud.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of DevLog
