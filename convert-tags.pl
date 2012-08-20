#!/usr/bin/perl

use strict;
use 5.10.0;
use utf8;

use Log::Contextual::SimpleLogger;
use Log::Contextual qw( :log ),
	-logger => Log::Contextual::SimpleLogger->new({ levels_upto => 'info' });

use JSON;
use Turtle::Writer;
use RDF::NS '20120521';
use constant NS => RDF::NS->new('20120521');
use File::Slurp::Unicode;
use autodie;

my $site = (shift @ARGV) // '';
my $dir = "data/$site";
die "Usage: $0 <site> [-d]\n" unless $site =~ /^[a-z]+$/ and -d $dir;

my $debug = grep { /^-d/ } @ARGV;

my $siteurl = "http://$site.stackexchange.com/";

*OUT = *STDOUT;
#binmode ':utf8', *OUT;
unless ($debug) {
	my $file = "$dir/tags-as-skos.ttl";
	say $file;
	open OUT, '>', $file; 
}

$SKOS::KnownTargets::MAP = {
	lcsh => [
		# qr{http://www.worldcat.org/search\?q=su%3A(.+)}) {
		# TODO: search at id.loc.gov
		# http://id.loc.gov/search/?q=Integrated+Library+systems
	],
	wikipedia => [
		qr{http://en.wikipedia.org/wiki/([^#?]+)} => sub { 
			"http://dbpedia.org/resource/$1";
		}
	],
	gnd => [ qr{http://d-nb.info/gnd/[0-9X-]+} ],
	jita => [ qr{http://eprints.rclis.org/handle/10760/[0-9]+} ],
};



my $tags = from_json(read_file("$dir/tags.json"));

my $wikis = from_json(read_file("$dir/wikis.json"));
$wikis = { map { $_->{tag_name} => $_ } @$wikis };

my $synonyms;
my %alias;
foreach ( @{ from_json(read_file("$dir/synonyms.json")) } ) {
	push @{$synonyms->{$_->{to_tag}}}, $_->{from_tag};
	$alias{$_->{from_tag}} = $_->{to_tag};
}

say OUT NS->TTL(qw(skos dcterms));
say OUT '@prefix library: <http://purl.org/library/> .';
say OUT "\@base <${siteurl}tags/> .";
say OUT turtle_statement '<>', 
	a => 'skos:ConceptScheme',
	'dcterms:license' => "<http://creativecommons.org/licenses/by-sa/>",
	'dcterms:source' => "<$siteurl>",
;

my %concepts;
foreach my $tag (@$tags) {
	my $name = $tag->{name};
	$concepts{$name} = {
		'skos:scopeNote' => { en => $wikis->{$name}->{excerpt} },
		'skos:prefLabel' => { en => $name }, 
		'skos:altLabel' => { en => $synonyms->{$name} },
		'library:holdingsCount' => $tag->{count},
	};
}

foreach my $tag (@$tags) {
	my $name = $tag->{name};
	my $w    = $wikis->{$name};
	my $prop = $concepts{$name};
	
	# links between tags
	while( $w->{body} =~ /([↓↑]?)<a href="\/questions\/tagged\/([^"]+)"/g ) {
		my ($rel,$to) = ($1,$2);
		$to = $alias{$to} if $alias{$to};
		unless ( $concepts{$to} ) {
			# TODO: link to tag wiki
			warn "tag '$to' referenced from '$name' not found!\n";
			next;
		}
		given($1) {
			when('↓') { 
				push @{$prop->{'skos:narrower'}}, "<$to>";
			};
			when('↑') { 
				push @{$concepts{$to}->{'skos:narrower'}}, "<$name>";
			};
			default { 
				push @{$prop->{'skos:related'}}, "<$to>";
			};
		}
	}

	# mappings to other knowledge organization systems
	my %mappings;
	while( $w->{body} =~ /(.?)<a href="(http[^"]+)"[^>]*>([^<]+)<\/a>/g ) {
		my ($rel,$url,$text) = ($1,$2,$3);

		my ($kos, $uri) = SKOS::KnownTargets::detect($url);
		push @{$mappings{$kos}}, "<$uri>" if $kos;
	}
	
	while (my ($name, $uris) = each %mappings) {
		my $rel = @$uris == 1 ? 'skos:closeMatch' : 'skos:narrowMatch';
		push @{$prop->{$rel}}, @$uris;
	}
}

foreach my $name (sort keys %concepts) {
	my $prop = $concepts{$name};
	say OUT turtle_statement "<$name>", a => 'skos:Concept', %$prop;
}

package SKOS::KnownTargets;
use Scalar::Util qw(reftype);

our $MAP = { };

sub detect {
	my $url = shift;

	while (my ($name, $m) = each %$MAP) {
		foreach(my $i = 0; $i < @$m; $i++) {
			my $e = $m->[$i];
			next unless reftype($e) eq 'SCALAR';
			next unless $url =~ $e;

			# we got a match
			while ($i<@$m and reftype($m->[$i]) eq 'SCALAR') { $i++; }
			return ($name,$url) if $i == @$m;

			my $uri = $m->[$i]->($url);
			return ($name,$uri) if $uri;
		}
	}

	return;
}
