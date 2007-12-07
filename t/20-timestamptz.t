#!/usr/bin/perl -w

use Test::More no_plan;
use strict;
BEGIN { use_ok("MooseX::TimestampTZ", qw(:all)); }

ok(defined &timestamp, "imported 'timestamp'");

is(timestamp(gmtime 1234567890),
   "2009-02-13 23:31:30",
   "timestamp()");

like(timestamptz(1234567890),
     qr{2009-02-1[34] \d{2}:\d{2}:\d{2}[\-+]\d{4}$},
     "timestamptz(Int)");

like(timestamptz,
     qr{2\d{3}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}[\-+]\d{4}$},
     "timestamptz()");

like(gmtimestamptz,
     qr{2\d{3}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}[\-+]\d{4}$},
     "gmtimestamptz()");

{
	package MyClass;
	use Moose;
	has 'stamp' =>
		(isa => "TimestampTZ",
		 is => "rw",
		 coerce => 1,
		);
	has 'local' =>
		(isa => "Timestamp",
		 is => "rw",
		 coerce => 1,
		);
	has 'epoch' =>
		(isa => "time_t",
		 is => "rw",
		 coerce => 1,
		);
}

my $obj = MyClass->new(stamp => "2007-01-02 12:00:12"); # ok
like($obj->stamp, qr{2007-01-02 12:00:12[\-+]\d+},
   "set value matching type constraint");

$obj->stamp("2007-01-02 12:01");
like($obj->stamp, qr{2007-01-02 12:01:00[\-+]\d+}, "coerce from Str");

$obj->stamp("2007-01-02 12");
like($obj->stamp, qr{2007-01-02 12:00:00[\-+]\d+}, "coerce from Str 2");

eval { $obj->stamp("2007-01-02 12:00:00Gibbons") };
isnt($@, "", "Gibbons is not a valid time zone")
	or diag("interpreted as: ".$obj->stamp);

$obj->stamp("2007010212");
like($obj->stamp, qr{2033-08-0[78] \d+:\d+:12[\-+]\d+},
     "no delimiters - interpreted as epoch");

$obj->stamp("2007-01-0212");
like($obj->stamp, qr{2007-01-02 12:00:00[\-+]\d+},
     "delimiters - interpreted as gregorian");

eval { $obj->stamp("2007-13-0212") };
isnt($@, "", "still detect invalid dates")
	or diag("interpreted as: ".$obj->stamp);

is(zone(0), "+0000", "zone(0)");
is(zone(0,1), "Z", "zone(0,1)");
is(zone(12*3600), "+1200", "zone(43200)");

is(offset_s("Z"), 0, "offset_s('Z')");
is(offset_s("+1200"), 43200, "offset_s(+1200)");
is(offset_s("+12"), 43200, "offset_s(+12)");
is(offset_s("-10"), -36000, "offset_s(-10)");

like(gmtimestamptz,
     qr{2\d{3}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}[\-+]\d{4}$},
     "gmtimestamptz()");

is(epoch("1970-01-01 00:01:00+0000"), 60, "epoch(+0000)");
is(epoch("1970-01-01 00:01:01Z"), 61, "epoch(Z)");
is(epoch("1970-01-01 12:01:02+12"), 62, "epoch(+12)");

$obj->stamp("2007-01-04 12:00:00+0143");
is($obj->stamp, "2007-01-04 12:00:00+0143", "funny time zones OK");

SKIP:{
	local($TODO) = "Moose coercion rules sort badly";
	eval { $obj->local($obj->stamp) };
	is($@, "", "TimestampTZ -> Timestamp conversion OK")
		or skip $TODO, 2;
	like($obj->local, qr{2\d{3}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}},
	     "coerced successfully");
	isnt(substr(($obj->local||""), 0, 19),
	     substr($obj->stamp, 0, 19),
	     "changed timezone on way in to Timestamp");
}

$obj->epoch($obj->stamp);
is($obj->epoch, 1167905820, "TimestampTZ => epoch conversion");

MooseX::TimestampTZ->import
	(gmtimestamptz => { use_z => 1,
			    -as => "gmtz" });

SKIP:{
	ok(defined &gmtz, "imported with renaming")
		or skip "failed to import, 1";
	is(&gmtz(0), "1970-01-01 00:00:00Z",
	   "curried function successfully");
}

$obj->stamp("1970-1-1Z");
is(epoch($obj->stamp), 0, "magic");

{
	local($TODO) = "Date::Manip format not yet accepted";
	ok(eval { epoch("2007010112:34:56") },
	   "Handles Date::Manip format");
}