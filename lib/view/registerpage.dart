import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';


class RegisterPage extends StatefulWidget{
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>{
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Register',
            style: TextStyle(
                fontSize: 35,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Form(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (String value) {

                        },
                        validator: (value) {
                          return value!.isEmpty ? 'Podaj adres email' : null;
                        }
                    ),
                  ),

                  SizedBox(height:30,),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: TextFormField(
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.password),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (String value) {},
                        validator: (value) {
                          return value!.isEmpty ? 'Podaj hasło' : null;
                        }
                    ),
                  ),

                  SizedBox(height: 30,),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: TextFormField(
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm your password',
                          prefixIcon: Icon(Icons.password),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (String value) {

                        },
                        validator: (value) {
                          return value!.isEmpty ? 'Hasła się nie zgadzają' : null;
                        }
                    ),
                  ),

                  SizedBox(height: 30,),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: MaterialButton(
                      minWidth: double.infinity,
                      onPressed: () {},
                      color: Colors.blueAccent,
                      textColor: Colors.white,
                      child: Text('Register'),
                    ),
                  ),
                  SizedBox(height: 12.5,),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: 'By tapping Register you agree to our\n',
                          style: TextStyle(
                            fontSize: 17.5,
                            color: Colors.blueAccent,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                                text: 'Terms of Service.',
                                recognizer: TapGestureRecognizer()..onTap = () {
                                  // Single tapped.
                                },
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                )
                            ),
                          ],
                        ),
                      )
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}