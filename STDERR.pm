
package Tie::STDERR;

use strict;

my $stderr;			### here we store the STDERR output

sub TIEHANDLE
	{
	my $class = shift;
	bless {}, $class;
	}
sub PRINT
	{
	my $self = shift;
	$stderr = '' unless defined $stderr;
	$stderr .= join	'', @_;
	}

my $default_user = 'root';			### change this to 'root'
my $default_subject = 'STDERR output detected';	### change this to your Subject
my $default_mail = '| /usr/lib/sendmail -t';	### default command

my ($user, $subject, $command);

END {
	if (defined $stderr)
		{
		if (defined $command)
			{
			open OUT, $command;
			print OUT $stderr;
			}
		else
			{
			open OUT, $default_mail;
			my $now = localtime;
			print OUT "To: $user\nSubject: $subject\n\nOutput to STDERR detected in $0:\n", $stderr, "\n\nTime: $now\n\n";
			print OUT "\%ENV:\n";
			for (sort keys %ENV) { print OUT "$_ = $ENV{$_}\n"; }
			}
		close OUT;
		}
	}

sub import
	{
	### print "Import @_ called\n";
	my $class = shift;

	if (@_ and not defined $_[0])	### explicit undef
		{
		$^W = 0;
		untie *STDERR if ref tied *STDERR eq 'Tie::STDERR';
		return;
		}

	return if -t STDERR or -t STDOUT;

	unless (ref tied *STDERR eq 'Tie::STDERR')
		{
		tie *STDERR, __PACKAGE__;

		$SIG{__WARN__} = sub { print STDERR @_; };

		$SIG{__DIE__} = sub { print STDERR @_; };
		}

	($user, $subject, $command) = ($default_user, $default_subject, undef);

	return unless @_;

	my $arg = shift;
	if ($arg =~ /^\s*[|>]/)
		{ $command = $arg; }
	else
		{
		$arg =~ s/\n$//;
		$user = $arg;
		$arg = shift;
		if (defined $arg)
			{ $arg =~ s/\n$//; $subject = $arg; }
		}
	}

use vars qw( $VERSION );

$VERSION = '0.122';

1;

__END__

=head1 NAME

Tie::STDERR - Send output of your STDERR to a process or mail

=head1 SYNOPSIS

	use Tie::STDERR;
	if (;

	use Tie::STDERR 'root';
	
	use Tie::STDERR 'root', 'Errors in the script';
	
	use Tie::STDERR '>> /tmp/log';
	
	use Tie::STDERR '| mail -s Error root';

=head1 DESCRIPTION

Send all output that would otherwise go to STDERR either by email to
root or whoever is responsible, or to a file or a process. This way
you can change the destination of your error messages from inside of
your script. The mail will be sent or the command run only if there
actually is some output detected -- something like cron would do.

The behaviour of the module is directed via the arguments to use, as
shown above. You can optionally give the name of the recipient and the
subject of the email. Argument that starts with | will send the output 
to a process. If it starts with > or >>, it will be written (appended)
to a file. If the argument is explicit undef, if will untie previous
tieness.

My main goal was to provide a tool that could be used easily,
especially (but not only) for CGI scripts. My assumption is that the
CGI scripts should run without anything being sent to STDERR (and
error_log, where it mixes up with other messages, even if you use
CGI::Carp). I've found it usefull to get delivered any relevant
information (%ENV) via email.

=head1 BUGS

The Tie::STDERR catches the compile time errors, but it doesn't get
the reason, only the fact that there was an error.

=head1 VERSION

0.122

=head1 AUTHOR

(c) 1998 Jan Pazdziora, adelton@fi.muni.cz,
http://www.fi.muni.cz/~adelton/ at Faculty of Informatics, Masaryk
University in Brno, Czech Republic

=cut

