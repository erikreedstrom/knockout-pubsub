# Knockout-PubSub

## Overview

**PubSub** allows you to decouple your complex VM structures by publishing observables (*and conversely subscribing to them*) using named strings.

### Usage

**PubSub** solves the issue of tight coupling which occurs when non-trival VMs need to be split to improve code maintainability, organization, and readability. This is especially important when encapsulating application logic within self-contained widgets.

Consider the following use case:

* A top-level reservation VM holds currenctly selected products within a reservation model
* A shopping cart VM displays these products
* An invoice VM displays these products
* A user can remove products from the shopping cart, but not the invoice

We will see that we can meet this requirement using **PubSub** in the following usage examples.

#### Publishing

`ko.observable`s `ko.observableArray`s and `ko.computed`s can all publish their changes with a simple extend command:

	ko.observable(value).extend({publish: "VM.observable"})

It is important to note that only one observable can be published to any given key.

Continuing the use case described previously, we know we will need to recieve notifications of updates from two VMs: *ReservationVM* and *ShoppingCartVM*.  To fulfill this, we create the observables and extend them to publish.

###### Coffeescript

	class ReservationVM
		constructor: () ->
			@products = ko.observableArray().extend(publish: "ReservationVM.products")

	class ShoppingCartVM
		constructor: () ->
			@products = ko.observableArray().extend(publish: "ShoppingCartVM.products")

###### JavaScript

	var ReservationVM, ShoppingCartVM;

	ReservationVM = (function() {
		function ReservationVM() {
			this.products = ko.observableArray().extend({publish: "ReservationVM.products"});
		}
		return ReservationVM;
	})();

	ShoppingCartVM = (function() {
		function ShoppingCartVM() {
			this.products = ko.observableArray().extend({publish: "ShoppingCartVM.products"});
		}
		return ShoppingCartVM;
	})();


#### Subscribing

`ko.observable`s and `ko.observableArray`s can subscribe to any number of published observables using the following command:

	ko.observable(value).extend({subscribe: "VM.observable"})

To subscribe to multiple sources, simply chain the extended calls:

	ko.observable(value)
		.extend({subscribe: "VM.observable"})
		.extend({subscribe: "VM2.observable"})

Again, following the use case from before, we will need to subscribe to changes of the products. Given that *ReservationVM* is our top-level VM, we'll subscribe our widgets to its products observable.

###### Coffeescript

	class ReservationVM
		constructor: () ->
			@products = ko.observableArray().extend(
				publish: "ReservationVM.products"
				subscribe: "ShoppingCartVM.products"
			)

	class ShoppingCartVM
		constructor: () ->
			@products = ko.observableArray().extend(
				publish: "ShoppingCartVM.products"
				subscribe: "ReservationVM.products"
			)

	class InvoiceVM
		constructor: () ->
		  	@products = ko.computed(->
		  		_products()
		  	)

		_products = ko.observableArray().extend(subscribe: "ReservationVM.products")

###### JavaScript

	var InvoiceVM, ReservationVM, ShoppingCartVM;

	ReservationVM = (function() {
		function ReservationVM() {
			this.products = ko.observableArray().extend({
				publish: "ReservationVM.products",
				subscribe: "ShoppingCartVM.products"
			});
		}
		return ReservationVM;
	})();

	ShoppingCartVM = (function() {
		function ShoppingCartVM() {
			this.products = ko.observableArray().extend({
				publish: "ShoppingCartVM.products",
				subscribe: "ReservationVM.products"
			});
		}
		return ShoppingCartVM;
	})();

	InvoiceVM = (function() {
		var _products;
		function InvoiceVM() {
			this.products = ko.computed(function() {
				return _products();
			});
		}
		_products = ko.observableArray().extend({
			subscribe: "ReservationVM.products"
		});
		return InvoiceVM;
	})();

We should now have a fully wired setup ready for us to test:

###### Coffeescript

	# Instantiate VMs
	reservation = new ReservationVM()
	shopping = new ShoppingCartVM()
	invoice = new InvoiceVM()

	# Set products on reservation
	reservation.products(["a","b","c"])

	# Observe update on all subscribers
	reservation.products() # => ["a", "b", "c"]
	shopping.products() # => ["a", "b", "c"]
	invoice.products() # => ["a", "b", "c"]

	# Remove item from shopping cart
	shopping.products.shift() # => "a"

	# Observe update on all subscribers
	reservation.products() # => ["b", "c"]
	shopping.products() # => ["b", "c"]
	invoice.products() # => ["b", "c"]