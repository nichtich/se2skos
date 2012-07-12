#!/usr/bin/perl

use strict;
use 5.10.0;
use utf8;

use JSON;
use Data::Dumper;

use lib 'lib';
use SKOS::Simple;
use File::Slurp::Unicode;
use GraphViz qw(2.04);

use Log::Contextual::SimpleLogger;
use Log::Contextual qw( :log ),
	-logger => Log::Contextual::SimpleLogger->new({ levels_upto => 'info' });

my $site = (shift @ARGV) // '';
my $dir = "data/$site";
die "Usage: $0 <site>" unless $site =~ /^[a-z]+$/ and -d $dir;

binmode ':utf8', *STDOUT;

my $siteurl = "http://$site.stackexchange.com/";

my $wikis    = from_json(read_file("$dir/wikis.json"));
my $synonyms = from_json(read_file("$dir/synonyms.json"));
my $tags     = from_json(read_file("$dir/tags.json"));

$tags  = { map { $_->{name} => $_ } @$tags };
$wikis = { map { $_->{tag_name} => $_ } @$wikis };
$synonyms = { map { $_->{from_tag} => $_ } @$synonyms };

my $skos = SKOS::Simple->new(
	base => $siteurl."tags/",
	identity => "label",
	license => "http://creativecommons.org/licenses/by-sa/",
	# TODO: add attribution!
);

my $g = GraphViz->new();

say STDERR (keys %$tags) . " tags";
say STDERR (keys %$wikis) . " tag wikis";

foreach my $w (values %$wikis) {
	my $tag = $w->{tag_name};

	# only tags with wiki and links are included
	next unless $w->{body} =~ /([↓]?)<a href="\/questions\/tagged\/([^"]+)"/;

	$skos->addConcept( label => $tag, scopeNote => $w->{excerpt} );
	$g->add_node( $tag );
	my @rel;	

	while( $w->{body} =~ /([↓]?)<a href="\/questions\/tagged\/([^"]+)"/g ) {
	#while( $w->{body} =~ /(.?)<a href="\/questions\/tagged\/([^"]+)"/g ) {
		my ($rel,$to) = ($1,$2);
		$to = $synonyms->{$to}->{to_tag} if $synonyms->{$to};
		given($1) {
			when('↓') { 
				$skos->addConcept( label => $tag, narrower => $to );
				$g->add_node( $to, color => 'gray' ) unless $wikis->{$to};
				$g->add_edge( $tag, $to, style => "bold" );
			};
			when('↑') { 
				$skos->addConcept( label => $tag, broader => $to );
				$g->add_node( $to, color => 'gray' ) unless $wikis->{$to};
				$g->add_edge( $to, $tag, style => "bold" );
			};
			when('') { 
				$skos->addConcept( label => $tag, related => $to );
				$g->add_edge( $tag, $to );
#				$g->add_edge( $tag, $to, constraint => 'false' );
			};
		}
	}

}

say "$dir/tags.ttl";
write_file( "$dir/tags-as-skos.ttl", $skos->turtle ); 

# create graphviz
say "$dir/tags.svg";
open (my $fh, '>', "$dir/tag-graph.svg");
print $fh $g->as_svg;
close $fh;

