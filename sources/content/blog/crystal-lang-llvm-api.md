+++
author = "ziprandom"
tags = ["emacs", "angular.js"]
title = "Crystal LLVM IR API"
date = "2016-04-28T16:00:00-03:00"
+++

Using crystals llvm bindings to create an LLVM IR for the simple addition example.

<!--more-->
```ruby
  require "llvm"

  LLVM.init_x86
  LLVM::Module.new("main").tap do | main_module |          # ; ModuleID = 'main'
	main_module.functions.add(                             # define i32 @main() {
	  "main",
	  Array.new(0, LLVM::Int32),
	  LLVM::Int32
	).basic_blocks.append "entry" do |builder|             # entry:
	  a = builder.alloca(LLVM::Int32,"a")                  #  %a = alloca i32
	  b = builder.alloca(LLVM::Int32,"b")                  #  %b = alloca i32
	  builder.store(LLVM.int(LLVM::Int32, 40), a)          #  store i32 40, i32* %a
	  builder.store(LLVM.int(LLVM::Int32, 6), b)           #  store i32 6, i32* %b
	  bval = builder.load(a, "val_a")                      #  %val_a = load i32* %a
	  aval = builder.load(b, "val_b")                      #  %val_b = load i32* %b
	  result = builder.add(aval, bval, "ab_val")           #  %ab_val = add i32 %val_b, %val_a
	  builder.ret result                                   #  ret i32 %ab_val
	end                                                    # }
  end.tap(&.dump).tap(&.verify).tap do | main_module |
	# execute in llvm
	engine = LLVM::JITCompiler.new( main_module)
	result = engine.run_function(
	  main_module.functions["main"],
	  [] of LLVM::GenericValue
	)
	pp result.to_i
  end.tap do | main_module |
	# generate bit code
	LibLLVM.write_bitcode_to_file(
	  main_module, "./out.bc"
	)
	`llc-3.6 -filetype=obj out.bc`
	`gcc -o out out.o`
	puts "wrote program to out\n\n"
	puts "run with: './out'\n\n"
	puts "doesn't have a print command\n\n"
	puts "see result with: 'echo $?'\n\n"
  end
```
