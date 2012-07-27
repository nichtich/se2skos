#!/usr/bin/perl

#
# Get all tags, synonyms, and tag wikis from a StackExchange site
# Result is written to the files `{tags|synonyms|wikis}.json` in
# directory data/$site/
#

use 5.10.0;
use JSON;
use Data::Dumper;

use File::Slurp;

use lib 'lib';
use StackExchange::API;

use Log::Contextual::SimpleLogger;
use Log::Contextual qw( :log ),
	-logger => Log::Contextual::SimpleLogger->new({ levels_upto => 'info' });

my $site = (shift @ARGV) // '';
$site =~ /^[a-z]+$/ or die "Usage: $0 <site> [-f]";

my $force = grep { /^-f/ } @ARGV;

my $dir = "data/$site";
mkdir($dir);

my $api = StackExchange::API->new( site => $site );

# File::Slurp sucks
sub write_file_utf8 {
    my $name = shift;
	open my $fh, '>:encoding(UTF-8)', $name
		or die "Couldn't create '$name': $!";
	local $/;
	print {$fh} $_ for @_;
}

sub write_json {
	write_file_utf8( $_[0], to_json($_[1],{pretty=>1,allow_nonref=>1}) );
}

sub get_cached {
	my ($file,$command) = @_;
	my $data;

	$file = "$dir/$file.json";
	if (!$force and -f $file ) {
		return from_json(read_file($file));
	} else {
		$data = $command->();
		write_json($file,$data);
	}

	return $data;
}

my $tags = get_cached( tags =>
	sub { $api->request_all('tags', order => 'desc') } );

my $synonyms = get_cached( synonyms =>
	sub { $api->request_all('tags/synonyms', order => 'desc' ); } );

my $wikis = get_cached( wikis => sub {
	my @names = map { $_->{name} } @$tags;
	my @items;

	while(@names) {
		my @cur;
		if (@names > 20) {
			@cur = splice(@names,0,20);
		} else {
			@cur = @names;
			@names = ();
		}
		my $path = "tags/".join(';',@cur)."/wikis";
		my $result = $api->request($path, filter => "withbody" ) || last;
		push @items, @{ $result->{items} } if $result->{items};
		sleep ($result->{backoff} || 1);
	}
	return \@items;
} );

